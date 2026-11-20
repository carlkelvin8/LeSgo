<?php

namespace Tests\Feature;

use App\Models\DriverLocation;
use App\Models\DriverProfile;
use App\Models\Order;
use App\Models\Partner;
use App\Models\PartnerStaff;
use App\Models\Service;
use App\Models\User;
use App\Models\Wallet;
use App\Services\RegistrationFeeService;
use Tests\TestCase;

/**
 * A refused request must change nothing, and store access must follow active staff.
 */
class OrderAccessRegressionTest extends TestCase
{
    private function merchant(): Partner
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'active', 'is_open' => true]);
        RegistrationFeeService::ensurePaymentRecord($owner)->update([
            'payment_status' => 'waived', 'waived_at' => now(), 'application_status' => 'approved', 'is_active' => true,
        ]);

        return $partner;
    }

    private function staff(Partner $partner, string $role = 'cook', bool $active = true): User
    {
        $user = User::factory()->create(['role' => 'partner_staff']);
        PartnerStaff::create(['partner_id' => $partner->id, 'user_id' => $user->id, 'role' => $role, 'is_active' => $active]);

        return $user;
    }

    private function customer(): User
    {
        $customer = User::factory()->create(['role' => 'customer']);
        Wallet::updateOrCreate(['user_id' => $customer->id], ['balance' => 0, 'currency' => 'PHP']);

        return $customer;
    }

    private function walletPaidOrder(Partner $partner, User $customer): Order
    {
        return Order::factory()->create([
            'partner_id' => $partner->id,
            'customer_id' => $customer->id,
            'service_id' => Service::factory()->create(['code' => 'LESEAT'])->id,
            'status' => 'pending',
            'payment_method' => 'wallet',
            'payment_status' => 'paid',
            'estimated_fare' => 100,
            'discount_amount' => 0,
        ]);
    }

    private function balance(User $user): float
    {
        return (float) Wallet::where('user_id', $user->id)->value('balance');
    }

    public function test_refused_cancellation_cannot_be_replayed_for_refunds(): void
    {
        $partner = $this->merchant();
        $customer = $this->customer();
        $order = $this->walletPaidOrder($partner, $customer);
        $body = ['status' => 'cancelled', 'payment_status' => 'paid'];

        foreach ([$this->staff($partner), $customer, $customer] as $actor) {
            $this->actingAs($actor, 'sanctum')
                ->patchJson("/api/v1/orders/{$order->id}/status", $body)
                ->assertForbidden();
        }

        $this->assertSame(0.0, $this->balance($customer));
        $this->assertSame('pending', $order->fresh()->status);
    }

    public function test_normal_cancellation_refunds_once(): void
    {
        $partner = $this->merchant();
        $customer = $this->customer();
        $order = $this->walletPaidOrder($partner, $customer);
        $staff = $this->staff($partner);
        $body = ['status' => 'cancelled', 'cancel_reason' => 'Out of stock'];

        $this->actingAs($staff, 'sanctum')->patchJson("/api/v1/orders/{$order->id}/status", $body)->assertOk();
        $this->actingAs($staff, 'sanctum')->patchJson("/api/v1/orders/{$order->id}/status", $body)->assertForbidden();

        $this->assertSame(100.0, $this->balance($customer));
        $this->assertSame('Out of stock', $order->fresh()->cancel_reason);
    }

    private function assignedRider(Order $order): User
    {
        $rider = User::factory()->create(['role' => 'driver']);
        $profile = DriverProfile::factory()->create(['user_id' => $rider->id, 'status' => 'active']);
        RegistrationFeeService::ensurePaymentRecord($rider)->update([
            'payment_status' => 'waived', 'waived_at' => now(), 'application_status' => 'approved', 'is_active' => true,
        ]);
        $order->update(['driver_id' => $profile->id, 'status' => 'accepted']);

        return $rider;
    }

    public function test_assigned_rider_can_cancel_before_pickup_but_others_cannot(): void
    {
        $partner = $this->merchant();
        $customer = $this->customer();
        $order = $this->walletPaidOrder($partner, $customer);
        $rider = $this->assignedRider($order);
        $body = ['status' => 'cancelled', 'cancel_reason' => 'Vehicle problem'];

        $other = $this->assignedRider($this->walletPaidOrder($partner, $this->customer()));
        $this->actingAs($other, 'sanctum')->patchJson("/api/v1/orders/{$order->id}/status", $body)->assertForbidden();

        $balanceBefore = $this->balance($customer);
        $this->actingAs($rider, 'sanctum')->patchJson("/api/v1/orders/{$order->id}/status", $body)->assertOk();
        // The rider backing out hands the order to other riders: the customer
        // keeps the order (no refund) and the store keeps preparing it.
        $this->assertSame('searching_driver', $order->fresh()->status);
        $this->assertNull($order->fresh()->driver_id);
        $this->assertSame($balanceBefore, $this->balance($customer));

        $picked = $this->walletPaidOrder($partner, $this->customer());
        $pickedRider = $this->assignedRider($picked);
        $picked->update(['status' => 'picked_up']);
        $this->actingAs($pickedRider, 'sanctum')->patchJson("/api/v1/orders/{$picked->id}/status", $body)->assertForbidden();
    }

    public function test_order_driver_location_finds_the_riders_latest_position(): void
    {
        $customer = $this->customer();
        $order = $this->walletPaidOrder($this->merchant(), $customer);
        $rider = $this->assignedRider($order);
        DriverLocation::create(['driver_id' => $rider->id, 'order_id' => $order->id, 'latitude' => 8.45, 'longitude' => 124.63, 'recorded_at' => now()]);

        $this->actingAs($customer, 'sanctum')
            ->getJson("/api/v1/orders/{$order->id}/driver-location")
            ->assertOk();
    }

    public function test_new_conversation_returns_a_numeric_order_id(): void
    {
        $customer = $this->customer();
        $order = $this->walletPaidOrder($this->merchant(), $customer);
        $this->assignedRider($order);

        $response = $this->actingAs($customer, 'sanctum')->getJson("/api/v1/chat/conversations/order/{$order->id}");

        $response->assertSuccessful();
        $this->assertIsInt($response->json('data.order_id'));
    }

    public function test_rider_history_filter_returns_only_their_own_orders(): void
    {
        $partner = $this->merchant();
        $mine = $this->walletPaidOrder($partner, $this->customer());
        $rider = $this->assignedRider($mine);
        $mine->update(['status' => 'completed']);
        $pool = $this->walletPaidOrder($partner, $this->customer());
        $pool->update(['status' => 'pending', 'payment_method' => 'cash', 'payment_status' => 'pending']);
        $other = $this->walletPaidOrder($partner, $this->customer());
        $this->assignedRider($other);

        $ids = fn ($response) => collect($response->json('data'))->pluck('id')->all();

        $filtered = $this->actingAs($rider, 'sanctum')->getJson('/api/v1/orders?mine=1&per_page=100')->assertOk();
        $this->assertSame([$mine->id], $ids($filtered));

        // Without the filter the open pool shares the list, which is what crowds history out.
        $unfiltered = $this->actingAs($rider, 'sanctum')->getJson('/api/v1/orders?per_page=100')->assertOk();
        $this->assertContains($pool->id, $ids($unfiltered));
        $this->assertContains($mine->id, $ids($unfiltered));
        $this->actingAs($this->customer(), 'sanctum')->getJson('/api/v1/orders?mine=1')->assertOk();
    }

    public function test_cancel_reason_only_changes_with_a_cancellation(): void
    {
        $partner = $this->merchant();
        $order = $this->walletPaidOrder($partner, $this->customer());

        $this->actingAs($this->staff($partner), 'sanctum')
            ->patchJson("/api/v1/orders/{$order->id}/status", ['cancel_reason' => 'scribble'])
            ->assertOk();

        $this->assertNull($order->fresh()->cancel_reason);
    }

    public function test_live_tracking_is_limited_to_people_on_the_order(): void
    {
        $partner = $this->merchant();
        $customer = $this->customer();
        $order = $this->walletPaidOrder($partner, $customer);
        $url = "/api/v1/tracking/order/{$order->id}/live";

        $this->actingAs($customer, 'sanctum')->getJson($url)->assertOk();
        $this->actingAs($partner->user, 'sanctum')->getJson($url)->assertOk();
        $this->actingAs($this->staff($partner), 'sanctum')->getJson($url)->assertOk();

        $this->actingAs($this->staff($partner, active: false), 'sanctum')->getJson($url)->assertForbidden();
        $this->actingAs($this->staff($this->merchant()), 'sanctum')->getJson($url)->assertForbidden();
        $this->actingAs($this->customer(), 'sanctum')->getJson($url)->assertForbidden();
    }

    public function test_money_staff_see_the_store_wallet_and_cannot_top_up(): void
    {
        $partner = $this->merchant();
        Wallet::updateOrCreate(['user_id' => $partner->user_id], ['balance' => 555, 'currency' => 'PHP']);
        $cashier = $this->staff($partner, 'cashier');

        $this->actingAs($cashier, 'sanctum')->getJson('/api/v1/wallets/my/wallet')
            ->assertOk()->assertJsonPath('data.user_id', $partner->user_id);
        $this->actingAs($this->staff($partner, 'cook'), 'sanctum')->getJson('/api/v1/wallets/my/wallet')
            ->assertOk()->assertJsonMissing(['user_id' => $partner->user_id]);
        $this->actingAs($this->staff($partner, 'cashier', active: false), 'sanctum')->getJson('/api/v1/wallets/my/wallet')
            ->assertJsonMissing(['user_id' => $partner->user_id]);
        $this->actingAs($this->staff($this->merchant(), 'cashier'), 'sanctum')->getJson("/api/v1/wallets/{$partner->user_id}")
            ->assertForbidden();

        $this->actingAs($cashier, 'sanctum')->postJson('/api/v1/wallets/my/topup', ['amount' => 100])->assertForbidden();
    }

    public function test_withdrawal_reads_need_wallet_access(): void
    {
        $partner = $this->merchant();
        Wallet::updateOrCreate(['user_id' => $partner->user_id], ['balance' => 555, 'currency' => 'PHP']);
        $url = '/api/v1/merchant/withdrawals/summary';

        $this->actingAs($partner->user, 'sanctum')->getJson($url)->assertOk();
        $this->actingAs($this->staff($partner, 'cashier'), 'sanctum')->getJson($url)->assertOk();
        $this->actingAs($this->staff($partner, 'admin'), 'sanctum')->getJson($url)->assertOk();

        $this->actingAs($this->staff($partner, 'cook'), 'sanctum')->getJson($url)->assertNotFound();
        $this->actingAs($this->staff($partner, 'admin', active: false), 'sanctum')->getJson($url)->assertNotFound();
    }

    public function test_deactivated_staff_cannot_open_proof_of_a_storeless_order(): void
    {
        $partner = $this->merchant();
        $order = Order::factory()->create([
            'partner_id' => null,
            'customer_id' => $this->customer()->id,
            'service_id' => Service::factory()->create()->id,
        ]);

        $this->actingAs($this->staff($partner, active: false), 'sanctum')
            ->getJson("/api/v1/proof-images/{$order->id}/missing.jpg")
            ->assertForbidden();
    }
}
