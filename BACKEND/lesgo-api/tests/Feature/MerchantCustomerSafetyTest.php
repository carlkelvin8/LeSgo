<?php

namespace Tests\Feature;

use App\Models\ChatReport;
use App\Models\MenuCategory;
use App\Models\MenuItem;
use App\Models\Order;
use App\Models\Partner;
use App\Models\PartnerStaff;
use App\Models\Service;
use App\Models\SupportTicket;
use App\Models\User;
use App\Models\UserBlock;
use App\Services\RegistrationFeeService;
use Tests\TestCase;

/**
 * Merchants have no chat with customers, so they report and block the
 * customer of an order instead (App Store Guideline 1.2).
 */
class MerchantCustomerSafetyTest extends TestCase
{
    private function merchant(): Partner
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'active', 'is_open' => true]);
        $fee = RegistrationFeeService::ensurePaymentRecord($owner);
        $fee->update(['payment_status' => 'waived', 'waived_at' => now(), 'application_status' => 'approved', 'is_active' => true]);

        return $partner;
    }

    private function orderFor(Partner $partner, ?User $customer = null): Order
    {
        return Order::factory()->create([
            'partner_id' => $partner->id,
            'customer_id' => ($customer ?? User::factory()->create(['role' => 'customer']))->id,
            'service_id' => Service::factory()->create(['code' => 'LESEAT'])->id,
            'status' => 'pending',
        ]);
    }

    private function staffFor(Partner $partner, bool $active = true): User
    {
        $staff = User::factory()->create(['role' => 'partner_staff']);
        PartnerStaff::create(['partner_id' => $partner->id, 'user_id' => $staff->id, 'role' => 'cook', 'is_active' => $active]);

        return $staff;
    }

    private function menuItem(Partner $partner): MenuItem
    {
        $category = MenuCategory::create(['partner_id' => $partner->id, 'name' => 'Meals', 'is_active' => true]);

        return MenuItem::create([
            'partner_id' => $partner->id, 'menu_category_id' => $category->id,
            'name' => 'Rice meal', 'price' => 100, 'is_available' => true,
        ]);
    }

    private function placeOrder(User $customer, Partner $partner): \Illuminate\Testing\TestResponse
    {
        $item = $this->menuItem($partner);
        $service = Service::query()->where('code', 'LESEAT')->first() ?? Service::factory()->create(['code' => 'LESEAT']);

        return $this->actingAs($customer, 'sanctum')->postJson('/api/v1/orders', [
            'service_id' => $service->id,
            'partner_id' => $partner->id,
            'estimated_distance_m' => 3000,
            'payment_method' => 'cash',
            'pickup' => ['address' => 'Store', 'lat' => 14.5995, 'lng' => 120.9842],
            'dropoff' => ['address' => 'Home', 'lat' => 14.6090, 'lng' => 121.0000],
            'items' => [['name' => 'Rice meal', 'quantity' => 1, 'estimated_price' => 100.0, 'menu_item_id' => $item->id]],
        ]);
    }

    // ── Report ───────────────────────────────────────────────────────────────

    public function test_owner_reports_the_customer_and_a_high_priority_ticket_is_filed(): void
    {
        $partner = $this->merchant();
        $customer = User::factory()->create(['role' => 'customer']);
        $order = $this->orderFor($partner, $customer);

        $this->actingAs($partner->user, 'sanctum')
            ->postJson("/api/v1/orders/{$order->id}/report-customer", ['reason' => 'harassment', 'details' => 'Abusive on the phone'])
            ->assertCreated()
            ->assertJsonPath('data.customer_blocked', false);

        $report = ChatReport::firstOrFail();
        $this->assertSame($customer->id, $report->reported_user_id);
        $this->assertSame($partner->user_id, $report->reporter_id);
        $this->assertNull($report->conversation_id);

        $ticket = SupportTicket::findOrFail($report->support_ticket_id);
        $this->assertSame('high', $ticket->priority);
        $this->assertSame($order->id, $ticket->order_id);
        $this->assertSame('customer_report', $ticket->metadata['type']);
        $this->assertSame(0, UserBlock::count());
    }

    public function test_report_with_block_also_blocks_the_customer(): void
    {
        $partner = $this->merchant();
        $customer = User::factory()->create(['role' => 'customer']);
        $order = $this->orderFor($partner, $customer);

        $this->actingAs($partner->user, 'sanctum')
            ->postJson("/api/v1/orders/{$order->id}/report-customer", ['reason' => 'spam_or_scam', 'block' => true])
            ->assertCreated()
            ->assertJsonPath('data.customer_blocked', true);

        $this->assertTrue(UserBlock::where('blocker_id', $partner->user_id)->where('blocked_id', $customer->id)->exists());
    }

    public function test_report_requires_a_known_reason(): void
    {
        $partner = $this->merchant();
        $order = $this->orderFor($partner);

        $this->actingAs($partner->user, 'sanctum')
            ->postJson("/api/v1/orders/{$order->id}/report-customer", ['reason' => 'because'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['reason']);
        $this->assertSame(0, ChatReport::count());
    }

    // ── Block / unblock and the ordering rule ───────────────────────────────

    public function test_blocked_customer_cannot_order_from_that_store_until_unblocked(): void
    {
        $partner = $this->merchant();
        $customer = User::factory()->create(['role' => 'customer']);
        $order = $this->orderFor($partner, $customer);

        $this->actingAs($partner->user, 'sanctum')
            ->getJson("/api/v1/orders/{$order->id}/customer-safety")
            ->assertOk()->assertJsonPath('data.customer_blocked', false);

        $this->actingAs($partner->user, 'sanctum')
            ->postJson("/api/v1/orders/{$order->id}/block-customer")
            ->assertOk()->assertJsonPath('data.customer_blocked', true);

        $this->actingAs($partner->user, 'sanctum')
            ->getJson("/api/v1/orders/{$order->id}/customer-safety")
            ->assertOk()->assertJsonPath('data.customer_blocked', true);

        $this->placeOrder($customer, $partner)
            ->assertForbidden()
            ->assertJsonPath('message', 'This store is not accepting orders from your account.');

        $this->actingAs($partner->user, 'sanctum')
            ->deleteJson("/api/v1/orders/{$order->id}/block-customer")
            ->assertOk()->assertJsonPath('data.customer_blocked', false);

        $this->placeOrder($customer, $partner)->assertCreated();
    }

    public function test_a_block_only_applies_to_the_store_that_set_it(): void
    {
        $partner = $this->merchant();
        $otherStore = $this->merchant();
        $customer = User::factory()->create(['role' => 'customer']);
        $order = $this->orderFor($partner, $customer);

        $this->actingAs($partner->user, 'sanctum')->postJson("/api/v1/orders/{$order->id}/block-customer")->assertOk();

        $this->placeOrder($customer, $otherStore)->assertCreated();
    }

    public function test_blocking_twice_is_harmless(): void
    {
        $partner = $this->merchant();
        $order = $this->orderFor($partner);

        $this->actingAs($partner->user, 'sanctum')->postJson("/api/v1/orders/{$order->id}/block-customer")->assertOk();
        $this->actingAs($partner->user, 'sanctum')->postJson("/api/v1/orders/{$order->id}/block-customer")->assertOk();

        $this->assertSame(1, UserBlock::count());
    }

    // ── Who may do it ────────────────────────────────────────────────────────

    public function test_staff_can_report_and_the_owner_is_recorded_as_the_blocker(): void
    {
        $partner = $this->merchant();
        $staff = $this->staffFor($partner);
        $customer = User::factory()->create(['role' => 'customer']);
        $order = $this->orderFor($partner, $customer);

        $this->actingAs($staff, 'sanctum')
            ->postJson("/api/v1/orders/{$order->id}/report-customer", ['reason' => 'harassment', 'block' => true])
            ->assertCreated();

        $this->assertSame($staff->id, ChatReport::firstOrFail()->reporter_id);
        $this->assertTrue(UserBlock::where('blocker_id', $partner->user_id)->where('blocked_id', $customer->id)->exists());
        $this->assertFalse(UserBlock::where('blocker_id', $staff->id)->exists());
    }

    public function test_inactive_staff_and_other_stores_cannot_act_on_the_order(): void
    {
        $partner = $this->merchant();
        $order = $this->orderFor($partner);

        $this->actingAs($this->staffFor($partner, active: false), 'sanctum')
            ->postJson("/api/v1/orders/{$order->id}/block-customer")->assertForbidden();

        $this->actingAs($this->merchant()->user, 'sanctum')
            ->postJson("/api/v1/orders/{$order->id}/report-customer", ['reason' => 'other'])->assertForbidden();
        $this->actingAs($this->merchant()->user, 'sanctum')
            ->getJson("/api/v1/orders/{$order->id}/customer-safety")->assertForbidden();

        $this->assertSame(0, ChatReport::count());
        $this->assertSame(0, UserBlock::count());
    }

    public function test_customers_and_guests_cannot_use_the_merchant_endpoints(): void
    {
        $partner = $this->merchant();
        $customer = User::factory()->create(['role' => 'customer']);
        $order = $this->orderFor($partner, $customer);

        $this->postJson("/api/v1/orders/{$order->id}/block-customer")->assertUnauthorized();
        $this->actingAs($customer, 'sanctum')
            ->postJson("/api/v1/orders/{$order->id}/block-customer")->assertForbidden();
        $this->assertSame(0, UserBlock::count());
    }

    public function test_a_store_cannot_report_or_block_its_own_account(): void
    {
        $partner = $this->merchant();
        $staff = $this->staffFor($partner);
        $selfOrder = $this->orderFor($partner, $partner->user);

        $this->actingAs($partner->user, 'sanctum')
            ->postJson("/api/v1/orders/{$selfOrder->id}/block-customer")->assertUnprocessable();
        $this->actingAs($staff, 'sanctum')
            ->postJson("/api/v1/orders/{$selfOrder->id}/report-customer", ['reason' => 'other'])->assertUnprocessable();

        $this->assertSame(0, UserBlock::count());
    }
}
