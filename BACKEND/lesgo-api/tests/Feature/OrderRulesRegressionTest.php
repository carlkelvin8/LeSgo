<?php

namespace Tests\Feature;

use App\Models\DriverProfile;
use App\Models\Order;
use App\Models\Partner;
use App\Models\Service;
use App\Models\SupportTicket;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use App\Services\RegistrationFeeService;
use App\Services\RiderCommissionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Order lifecycle rules around duty status, merchant readiness, cancellation,
 * shipping-fee hold settlement and support ticket intake.
 */
class OrderRulesRegressionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Queue::fake();
    }

    private function approve(User $user): void
    {
        RegistrationFeeService::ensurePaymentRecord($user)->update([
            'payment_status' => 'waived', 'waived_at' => now(), 'application_status' => 'approved', 'is_active' => true,
        ]);
    }

    /** @return array{0: User, 1: DriverProfile} */
    private function rider(float $walletBalance = 1000.0, bool $onDuty = true): array
    {
        $user = User::factory()->create(['role' => 'driver']);
        $profile = DriverProfile::factory()->create([
            'user_id' => $user->id,
            'status' => 'active',
            'is_available' => $onDuty,
            'package_tier' => 'basic',
        ]);
        $this->approve($user);
        Wallet::updateOrCreate(['user_id' => $user->id], ['balance' => $walletBalance, 'currency' => 'PHP']);

        return [$user, $profile];
    }

    private function merchant(): Partner
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'active', 'is_open' => true]);
        $this->approve($owner);

        return $partner;
    }

    private function customer(float $balance = 0.0): User
    {
        $customer = User::factory()->create(['role' => 'customer']);
        Wallet::updateOrCreate(['user_id' => $customer->id], ['balance' => $balance, 'currency' => 'PHP']);

        return $customer;
    }

    private function order(array $attributes = []): Order
    {
        return Order::factory()->create(array_merge([
            'customer_id' => $this->customer()->id,
            'service_id' => Service::factory()->create(['code' => 'LESGO'])->id,
            'status' => 'pending',
            'payment_method' => 'cash',
            'payment_status' => 'pending',
            'estimated_fare' => 100,
        ], $attributes));
    }

    private function balance(User $user): float
    {
        return (float) Wallet::where('user_id', $user->id)->value('balance');
    }

    private function setStatus(User $actor, Order $order, array $body)
    {
        return $this->actingAs($actor, 'sanctum')->patchJson("/api/v1/orders/{$order->id}/status", $body);
    }

    private function listedIds(User $actor, string $query = ''): array
    {
        $response = $this->actingAs($actor, 'sanctum')->getJson('/api/v1/orders?per_page=100'.$query)->assertOk();

        return collect($response->json('data.data') ?? $response->json('data'))->pluck('id')->all();
    }

    // ---------------------------------------------------------------- 1. duty

    public function test_off_duty_rider_is_told_to_go_on_duty_and_nothing_is_charged(): void
    {
        [$rider, $profile] = $this->rider(onDuty: false);
        $order = $this->order();

        $this->setStatus($rider, $order, ['status' => 'accepted'])
            ->assertForbidden()
            ->assertJsonPath('message', 'Go on duty before accepting orders.');

        $this->assertNull($order->fresh()->driver_id);
        $this->assertSame('pending', $order->fresh()->status);
        $this->assertSame(1000.0, $this->balance($rider));
        $this->assertSame(0, WalletTransaction::count());

        // Going on duty makes the very same request succeed.
        $profile->update(['is_available' => true]);
        $this->setStatus($rider, $order, ['status' => 'accepted'])->assertOk();
    }

    public function test_off_duty_rider_does_not_see_the_open_pool_but_still_sees_assigned_orders(): void
    {
        [$rider, $profile] = $this->rider(onDuty: false);
        $pool = $this->order();
        $assigned = $this->order(['driver_id' => $profile->id, 'status' => 'accepted']);
        $someoneElses = $this->order(['driver_id' => DriverProfile::factory()->create(['status' => 'active'])->id, 'status' => 'accepted']);

        $ids = $this->listedIds($rider);

        $this->assertContains($assigned->id, $ids);
        $this->assertNotContains($pool->id, $ids);
        $this->assertNotContains($someoneElses->id, $ids);

        $profile->update(['is_available' => true]);
        $onDutyIds = $this->listedIds($rider);
        $this->assertContains($pool->id, $onDutyIds);
        $this->assertContains($assigned->id, $onDutyIds);
    }

    // ------------------------------------------------- 2. merchant readiness

    public function test_rider_can_pick_up_a_partner_order_only_after_the_merchant_marks_it_ready(): void
    {
        $partner = $this->merchant();
        [$rider, $profile] = $this->rider();
        $order = $this->order(['partner_id' => $partner->id, 'driver_id' => $profile->id, 'status' => 'accepted']);

        $this->setStatus($rider, $order, ['status' => 'picked_up'])->assertStatus(409);
        $this->assertSame('accepted', $order->fresh()->status);
        $this->assertNull($order->fresh()->picked_up_at);

        $this->setStatus($partner->user, $order, ['status' => 'ready_for_pickup'])->assertOk();
        $this->assertNotNull($order->fresh()->ready_for_pickup_at);

        $this->setStatus($rider, $order, ['status' => 'picked_up'])
            ->assertOk()
            ->assertJsonPath('data.status', 'picked_up');
        $this->assertNotNull($order->fresh()->picked_up_at);
    }

    public function test_merchant_can_mark_ready_after_the_rider_already_tapped_in_progress(): void
    {
        $partner = $this->merchant();
        [$rider, $profile] = $this->rider();
        $order = $this->order(['partner_id' => $partner->id, 'driver_id' => $profile->id, 'status' => 'in_progress']);

        // The rider cannot pick up yet, so the merchant must still be able to finish.
        $this->setStatus($rider, $order, ['status' => 'picked_up'])->assertStatus(409);
        $this->setStatus($partner->user, $order, ['status' => 'ready_for_pickup'])->assertOk();
        $this->assertNotNull($order->fresh()->ready_for_pickup_at);
        $this->assertSame('in_progress', $order->fresh()->status);

        $this->setStatus($rider, $order, ['status' => 'picked_up'])->assertOk();
    }

    public function test_orders_without_a_partner_need_no_merchant_readiness(): void
    {
        [$rider, $profile] = $this->rider();
        $order = $this->order(['driver_id' => $profile->id, 'status' => 'accepted']);

        $this->setStatus($rider, $order, ['status' => 'picked_up'])->assertOk();
    }

    // ----------------------------------------- 3. refused requests are inert

    public function test_refused_rider_cancellation_after_pickup_changes_nothing_however_often_it_is_repeated(): void
    {
        $partner = $this->merchant();
        $customer = $this->customer();
        [$rider, $profile] = $this->rider();
        $order = $this->order([
            'partner_id' => $partner->id,
            'customer_id' => $customer->id,
            'driver_id' => $profile->id,
            'status' => 'picked_up',
            'ready_for_pickup_at' => now(),
            'payment_method' => 'wallet',
            'payment_status' => 'paid',
        ]);

        foreach (range(1, 3) as $_) {
            $this->setStatus($rider, $order, ['status' => 'cancelled', 'cancel_reason' => 'changed my mind'])->assertForbidden();
        }

        $fresh = $order->fresh();
        $this->assertSame('picked_up', $fresh->status);
        $this->assertSame('paid', $fresh->payment_status);
        $this->assertNull($fresh->cancel_reason);
        $this->assertNull($fresh->cancelled_at);
        $this->assertSame(0.0, $this->balance($customer));
        $this->assertSame(0, WalletTransaction::count());
    }

    public function test_unrelated_user_cannot_cancel_and_never_triggers_a_refund(): void
    {
        $customer = $this->customer();
        $stranger = $this->customer();
        $order = $this->order(['customer_id' => $customer->id, 'payment_method' => 'wallet', 'payment_status' => 'paid']);

        foreach (range(1, 2) as $_) {
            $this->setStatus($stranger, $order, ['status' => 'cancelled'])->assertForbidden();
        }

        $this->assertSame('pending', $order->fresh()->status);
        $this->assertSame(0.0, $this->balance($customer));
        $this->assertSame(0.0, $this->balance($stranger));
        $this->assertSame(0, WalletTransaction::count());
    }

    // ------------------------------------- 4. completion releases the hold

    public function test_completing_an_order_refunds_the_hold_taken_on_the_higher_estimate(): void
    {
        [$rider, $profile] = $this->rider(1000.0);
        // Basic tier (platform 30%): estimate 500 -> hold PHP 150. Actual fare 150 -> hold should have been PHP 45.
        $order = $this->order(['estimated_fare' => 500, 'actual_fare' => 150]);

        $this->setStatus($rider, $order, ['status' => 'accepted'])->assertOk();
        $this->assertSame(850.0, $this->balance($rider));

        $order->update(['status' => 'picked_up', 'proof_images' => ['proofs/delivery.jpg']]);
        $this->setStatus($rider, $order, ['status' => 'completed'])
            ->assertOk()
            ->assertJsonPath('data.status', 'completed');

        // PHP 150 held, PHP 105 released.
        $this->assertSame(955.0, $this->balance($rider));
        $this->assertSame(
            RiderCommissionService::resolveShippingFee($order->fresh(), 150.0),
            round(1000.0 - $this->balance($rider), 2)
        );
        $meta = $order->fresh()->meta;
        $this->assertTrue($meta['driver_hold_adjusted']);
        $this->assertEquals(105.0, $meta['driver_hold_adjustment_amount']);

        $credits = WalletTransaction::where('type', 'credit')->where('source_id', $order->id)->get();
        $this->assertCount(1, $credits);
        $this->assertEquals(105.0, (float) $credits->first()->amount);
    }

    public function test_completing_an_order_keeps_the_hold_when_actual_fare_matches_the_estimate(): void
    {
        [$rider] = $this->rider(1000.0);
        $order = $this->order(['estimated_fare' => 500, 'actual_fare' => 500]);

        $this->setStatus($rider, $order, ['status' => 'accepted'])->assertOk();
        $order->update(['status' => 'picked_up', 'proof_images' => ['proofs/delivery.jpg']]);
        $this->setStatus($rider, $order, ['status' => 'completed'])->assertOk();

        $this->assertSame(850.0, $this->balance($rider));
        $this->assertEmpty($order->fresh()->meta['driver_hold_adjusted'] ?? null);
    }

    public function test_shipping_fee_can_be_priced_on_a_fare_other_than_the_estimate(): void
    {
        $order = new Order(['estimated_fare' => 500]);

        // No rider assigned: Basic tier platform cut (30%).
        $this->assertSame(150.0, RiderCommissionService::resolveShippingFee($order));
        $this->assertSame(45.0, RiderCommissionService::resolveShippingFee($order, 150.0));
        $this->assertSame(10.0, RiderCommissionService::resolveShippingFee($order, 20.0), 'minimum hold is PHP 10');
    }

    // ------------------------------- 4b. online-paid orders are paid out

    private function completedOnlineFoodOrder(Partner $partner, array $attributes = []): array
    {
        [$rider, $profile] = $this->rider(1000.0);
        $order = $this->order(array_merge([
            'partner_id' => $partner->id,
            'service_id' => Service::factory()->create(['code' => 'LESEAT'])->id,
            'payment_method' => 'gcash',
            'payment_status' => 'paid',
            'estimated_fare' => 100,
            'actual_fare' => 100,
            'ready_for_pickup_at' => now(),
        ], $attributes));
        \App\Models\LesbuyItem::create(['order_id' => $order->id, 'name' => 'Burger', 'quantity' => 2, 'estimated_price' => 150]);
        \App\Models\LesbuyItem::create(['order_id' => $order->id, 'name' => 'Fries', 'quantity' => 1, 'estimated_price' => 60, 'actual_price' => 50]);

        $this->setStatus($rider, $order, ['status' => 'accepted'])->assertOk();
        $order->update(['status' => 'picked_up', 'proof_images' => ['proofs/delivery.jpg']]);

        return [$rider, $order];
    }

    public function test_online_paid_order_pays_the_store_its_items_and_the_rider_the_fare_once(): void
    {
        $partner = $this->merchant();
        Wallet::updateOrCreate(['user_id' => $partner->user_id], ['balance' => 0, 'currency' => 'PHP']);
        [$rider, $order] = $this->completedOnlineFoodOrder($partner);

        // Accepting held the Basic-tier platform cut: 30% of PHP 100.
        $this->assertSame(970.0, $this->balance($rider));

        $this->setStatus($rider, $order, ['status' => 'completed'])->assertOk();

        // Store: 2 x 150 + 1 x 50 (actual price wins) = 350. Rider: fare 100.
        $this->assertSame(350.0, $this->balance($partner->user));
        $this->assertSame(1070.0, $this->balance($rider), 'rider nets fare minus the 30% hold = driver_share 70');
        $this->assertEquals(70.0, (float) $order->fresh()->driver_share);
        $meta = $order->fresh()->meta;
        $this->assertTrue($meta['merchant_settled']);
        $this->assertTrue($meta['driver_settled']);

        // Replaying completion never pays twice.
        $this->setStatus($rider, $order, ['status' => 'completed']);
        \App\Services\OrderSettlementService::settleCompletedOrder($order->fresh());
        $this->assertSame(350.0, $this->balance($partner->user));
        $this->assertSame(1070.0, $this->balance($rider));
    }

    public function test_cash_orders_are_not_paid_out_from_the_platform(): void
    {
        $partner = $this->merchant();
        Wallet::updateOrCreate(['user_id' => $partner->user_id], ['balance' => 0, 'currency' => 'PHP']);
        [$rider, $order] = $this->completedOnlineFoodOrder($partner, ['payment_method' => 'cash', 'payment_status' => 'pending']);

        $this->setStatus($rider, $order, ['status' => 'completed'])->assertOk();

        $this->assertSame(0.0, $this->balance($partner->user));
        $this->assertSame(970.0, $this->balance($rider), 'cash: the rider collected the money, only the hold moved');
    }

    public function test_hold_follows_the_riders_package_tier(): void
    {
        foreach (['basic' => 970.0, 'advance' => 980.0, 'pro' => 990.0] as $tier => $expected) {
            [$rider, $profile] = $this->rider(1000.0);
            $profile->update(['package_tier' => $tier]);
            $order = $this->order(['estimated_fare' => 100]);

            $this->setStatus($rider, $order, ['status' => 'accepted'])->assertOk();
            $this->assertSame($expected, $this->balance($rider), "{$tier} tier hold");
        }
    }

    public function test_reported_distance_cannot_be_shorter_than_the_straight_line(): void
    {
        [$rider, $profile] = $this->rider();
        // About 1.1 km apart.
        $order = $this->order([
            'driver_id' => $profile->id,
            'status' => 'picked_up',
            'pickup_lat' => 14.5995, 'pickup_lng' => 120.9842,
            'dropoff_lat' => 14.6095, 'dropoff_lng' => 120.9842,
        ]);

        $this->setStatus($rider, $order, ['actual_distance_m' => 10])->assertOk();

        $this->assertGreaterThan(1000, $order->fresh()->actual_distance_m);
    }

    // ------------------------------------------------- 5. who can cancel

    public function test_merchant_cannot_cancel_once_a_driver_is_assigned_in_any_state(): void
    {
        $partner = $this->merchant();
        [, $profile] = $this->rider();

        foreach (['accepted', 'ready_for_pickup', 'driver_arrived_at_pickup'] as $state) {
            $order = $this->order(['partner_id' => $partner->id, 'driver_id' => $profile->id, 'status' => $state]);

            $this->setStatus($partner->user, $order, ['status' => 'cancelled'])->assertForbidden();
            $this->assertSame($state, $order->fresh()->status, "merchant must not cancel from {$state}");
        }

        // Without a driver the merchant still can.
        $open = $this->order(['partner_id' => $partner->id, 'status' => 'searching_driver']);
        $this->setStatus($partner->user, $open, ['status' => 'cancelled'])->assertOk();
    }

    public function test_assigned_rider_backing_out_before_pickup_passes_the_order_to_other_riders(): void
    {
        $partner = $this->merchant();

        foreach (['accepted', 'ready_for_pickup', 'driver_arrived_at_pickup', 'in_progress'] as $state) {
            $customer = $this->customer();
            [$rider, $profile] = $this->rider();
            $order = $this->order([
                'partner_id' => $partner->id,
                'customer_id' => $customer->id,
                'driver_id' => $profile->id,
                'status' => $state,
                'payment_method' => 'wallet',
                'payment_status' => 'paid',
                'estimated_fare' => 100,
                'discount_amount' => 0,
            ]);

            $body = ['status' => 'cancelled', 'cancel_reason' => 'Vehicle problem'];
            $this->setStatus($rider, $order, $body)->assertOk();
            $this->setStatus($rider, $order, $body)->assertForbidden();

            $fresh = $order->fresh();
            $this->assertContains($fresh->status, ['searching_driver', 'ready_for_pickup'], "rider release from {$state}");
            $this->assertNull($fresh->driver_id, "rider unassigned from {$state}");
            $this->assertNull($fresh->cancelled_at);
            $this->assertSame('Vehicle problem', $fresh->meta['rider_releases'][0]['reason']);
            $this->assertSame(0.0, $this->balance($customer), "customer keeps the paid order from {$state}");
        }
    }

    public function test_rider_who_left_a_booking_never_gets_it_back_but_other_riders_do(): void
    {
        $partner = $this->merchant();
        [$quitter, $quitterProfile] = $this->rider();
        [$other] = $this->rider();
        $order = $this->order([
            'partner_id' => $partner->id,
            'driver_id' => $quitterProfile->id,
            'status' => 'accepted',
            'ready_for_pickup_at' => now(),
        ]);

        $this->setStatus($quitter, $order, ['status' => 'cancelled', 'cancel_reason' => 'Flat tire'])->assertOk();
        $this->assertSame('ready_for_pickup', $order->fresh()->status);

        // Hidden from the rider who left it, still offered to everyone else.
        $this->assertNotContains($order->id, $this->listedIds($quitter));
        $this->assertContains($order->id, $this->listedIds($other));

        $this->setStatus($quitter, $order, ['status' => 'accepted'])->assertForbidden();
        $this->setStatus($other, $order, ['status' => 'accepted'])->assertOk();
        $this->assertNotSame($quitterProfile->id, $order->fresh()->driver_id);
    }

    public function test_rider_today_earnings_follow_the_philippine_day(): void
    {
        // 09:00 PHT on Nov 10 (01:00 UTC).
        \Illuminate\Support\Carbon::setTestNow(\Illuminate\Support\Carbon::parse('2026-11-10 01:00:00', 'UTC'));
        try {
            [$rider, $profile] = $this->rider();
            // 01:00 PHT Nov 10 -> today in the Philippines (still Nov 9 in UTC).
            $early = $this->order(['driver_id' => $profile->id, 'status' => 'completed', 'completed_at' => '2026-11-09 17:00:00']);
            // 23:00 PHT Nov 9 -> yesterday.
            $yesterday = $this->order(['driver_id' => $profile->id, 'status' => 'completed', 'completed_at' => '2026-11-09 15:00:00']);

            $today = app(\App\Services\DriverEarningsService::class)->getEarnings($rider->fresh(), 'today');

            $ids = collect($today['entries'])->pluck('order_id')->all();
            $this->assertContains($early->id, $ids);
            $this->assertNotContains($yesterday->id, $ids);
            $this->assertSame(1, $today['summary']['completed_trips']);
        } finally {
            \Illuminate\Support\Carbon::setTestNow();
        }
    }

    // ----------------------------------------------------------- 6. ?mine=1

    public function test_mine_filter_keeps_other_riders_and_the_pool_out_of_a_riders_list(): void
    {
        [$rider, $profile] = $this->rider();
        $mineActive = $this->order(['driver_id' => $profile->id, 'status' => 'accepted']);
        $mineDone = $this->order(['driver_id' => $profile->id, 'status' => 'completed']);
        $pool = $this->order();
        $other = $this->order(['driver_id' => DriverProfile::factory()->create(['status' => 'active'])->id, 'status' => 'accepted']);

        $mineOnly = $this->listedIds($rider, '&mine=1');
        sort($mineOnly);
        $expected = [$mineActive->id, $mineDone->id];
        sort($expected);

        $this->assertSame($expected, $mineOnly);
        $this->assertContains($pool->id, $this->listedIds($rider));
        $this->assertNotContains($other->id, $this->listedIds($rider));
    }

    // ------------------------------------------------ 7. support ticket intake

    public function test_support_ticket_with_legacy_general_category_is_stored_as_general_inquiry(): void
    {
        $user = $this->customer();
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/support/tickets', [
            'subject' => 'Help', 'description' => 'Where is my payout?', 'category' => 'general',
        ])->assertCreated();

        $this->assertDatabaseHas('support_tickets', ['user_id' => $user->id, 'category' => 'general_inquiry']);
        $this->assertDatabaseCount('support_ticket_messages', 1);
    }

    public function test_support_ticket_without_a_category_defaults_to_general_inquiry(): void
    {
        $user = $this->customer();
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/support/tickets', ['subject' => 'Help', 'description' => 'Hello'])->assertCreated();

        $this->assertDatabaseHas('support_tickets', ['user_id' => $user->id, 'category' => 'general_inquiry']);
    }

    public function test_support_ticket_with_unknown_category_is_rejected_not_swallowed(): void
    {
        $user = $this->customer();
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/support/tickets', [
            'subject' => 'Help', 'description' => 'Hello', 'category' => 'not_a_category',
        ])->assertStatus(422)->assertJsonValidationErrors('category');

        $this->assertDatabaseCount('support_tickets', 0);
    }

    public function test_failed_support_ticket_insert_is_reported_as_an_error_not_success(): void
    {
        $user = $this->customer();
        Sanctum::actingAs($user);
        SupportTicket::creating(function () {
            throw new \RuntimeException('database is unavailable');
        });

        $response = $this->postJson('/api/v1/support/tickets', [
            'subject' => 'Help', 'description' => 'Hello', 'category' => 'app_bug',
        ]);

        $response->assertStatus(500);
        $this->assertNotTrue($response->json('success'));
        $this->assertDatabaseCount('support_tickets', 0);
    }
}
