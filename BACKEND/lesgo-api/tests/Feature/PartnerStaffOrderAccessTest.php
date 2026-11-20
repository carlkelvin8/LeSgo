<?php

namespace Tests\Feature;

use App\Models\LesbuyItem;
use App\Models\Order;
use App\Models\Partner;
use App\Models\PartnerStaff;
use App\Models\Service;
use App\Models\User;
use App\Services\RegistrationFeeService;
use Tests\TestCase;

/**
 * Staff work the store's orders. The order access check read a users.partner_id
 * that does not exist, so every staff request was a silent 403.
 */
class PartnerStaffOrderAccessTest extends TestCase
{
    private function merchant(): Partner
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'active', 'is_open' => true]);
        $fee = RegistrationFeeService::ensurePaymentRecord($owner);
        $fee->update(['payment_status' => 'waived', 'waived_at' => now(), 'application_status' => 'approved', 'is_active' => true]);

        return $partner;
    }

    private function orderFor(Partner $partner): Order
    {
        return Order::factory()->create([
            'partner_id' => $partner->id,
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

    public function test_active_staff_can_view_their_stores_order_but_not_another_stores(): void
    {
        $partner = $this->merchant();
        $staff = $this->staffFor($partner);

        $this->actingAs($staff, 'sanctum')
            ->getJson("/api/v1/orders/{$this->orderFor($partner)->id}")->assertOk();
        $this->actingAs($staff, 'sanctum')
            ->getJson("/api/v1/orders/{$this->orderFor($this->merchant())->id}")->assertForbidden();
    }

    public function test_deactivated_staff_lose_access(): void
    {
        $partner = $this->merchant();

        $this->actingAs($this->staffFor($partner, active: false), 'sanctum')
            ->getJson("/api/v1/orders/{$this->orderFor($partner)->id}")->assertForbidden();
    }

    public function test_staff_order_list_shows_only_their_store(): void
    {
        $partner = $this->merchant();
        $own = $this->orderFor($partner);
        $this->orderFor($this->merchant());

        $this->actingAs($this->staffFor($partner), 'sanctum')
            ->getJson('/api/v1/orders')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $own->id);

        $this->actingAs($this->staffFor($partner, active: false), 'sanctum')
            ->getJson('/api/v1/orders')
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_item_without_options_is_listed_with_null_options(): void
    {
        $partner = $this->merchant();
        $order = $this->orderFor($partner);
        $empty = LesbuyItem::create(['order_id' => $order->id, 'name' => 'Rice', 'quantity' => 1, 'selected_options' => []]);
        LesbuyItem::create([
            'order_id' => $order->id,
            'name' => 'Tea',
            'quantity' => 1,
            'selected_options' => ['size' => ['label' => 'Large', 'price' => 20]],
        ]);

        $items = $this->actingAs($partner->user, 'sanctum')
            ->getJson('/api/v1/orders')
            ->assertOk()
            ->json('data.0.lesbuy_items');

        $this->assertNull(collect($items)->firstWhere('id', $empty->id)['selected_options']);
        $this->assertSame('Large', collect($items)->firstWhere('name', 'Tea')['selected_options']['size']['label']);
    }

    public function test_staff_can_accept_mark_ready_and_reject_only_their_stores_orders(): void
    {
        $partner = $this->merchant();
        $staff = $this->staffFor($partner);
        $order = $this->orderFor($partner);

        $this->actingAs($staff, 'sanctum')
            ->patchJson("/api/v1/orders/{$order->id}/status", ['status' => 'searching_driver'])->assertOk();
        $this->actingAs($staff, 'sanctum')
            ->patchJson("/api/v1/orders/{$order->id}/status", ['status' => 'ready_for_pickup'])->assertOk();
        $this->actingAs($staff, 'sanctum')
            ->patchJson("/api/v1/orders/{$this->orderFor($partner)->id}/status", ['status' => 'cancelled', 'cancel_reason' => 'Out of stock'])
            ->assertOk();

        $this->actingAs($staff, 'sanctum')
            ->patchJson("/api/v1/orders/{$this->orderFor($this->merchant())->id}/status", ['status' => 'searching_driver'])
            ->assertForbidden();
        $this->actingAs($this->staffFor($partner, active: false), 'sanctum')
            ->patchJson("/api/v1/orders/{$this->orderFor($partner)->id}/status", ['status' => 'searching_driver'])
            ->assertForbidden();
    }

    public function test_staff_cannot_run_orders_while_the_store_is_restricted(): void
    {
        $partner = $this->merchant();
        RegistrationFeeService::ensurePaymentRecord($partner->user)->update(['is_active' => false, 'payment_status' => 'pending', 'application_status' => 'pending']);

        $this->actingAs($this->staffFor($partner), 'sanctum')
            ->patchJson("/api/v1/orders/{$this->orderFor($partner)->id}/status", ['status' => 'searching_driver'])
            ->assertForbidden();
    }

    public function test_cook_can_read_the_menu_but_only_staff_admin_can_edit_it(): void
    {
        $partner = $this->merchant();
        $cook = $this->staffFor($partner);
        $admin = User::factory()->create(['role' => 'partner_staff']);
        PartnerStaff::create(['partner_id' => $partner->id, 'user_id' => $admin->id, 'role' => 'admin', 'is_active' => true]);
        $category = ['name' => 'Meals'];

        $this->actingAs($cook, 'sanctum')->getJson("/api/v1/partners/{$partner->id}/merchant-menu")->assertOk();
        $this->actingAs($cook, 'sanctum')->getJson("/api/v1/partners/{$partner->id}/menu-items")->assertOk();
        $this->actingAs($cook, 'sanctum')->postJson("/api/v1/partners/{$partner->id}/menu-categories", $category)->assertForbidden();

        $this->actingAs($admin, 'sanctum')->postJson("/api/v1/partners/{$partner->id}/menu-categories", $category)->assertSuccessful();

        $otherStore = $this->merchant();
        $this->actingAs($cook, 'sanctum')->getJson("/api/v1/partners/{$otherStore->id}/merchant-menu")->assertForbidden();
        $this->actingAs($admin, 'sanctum')->postJson("/api/v1/partners/{$otherStore->id}/menu-categories", $category)->assertForbidden();
    }

    public function test_working_partner_id_covers_owner_staff_and_everyone_else(): void
    {
        $partner = $this->merchant();

        $this->assertSame($partner->id, $partner->user->workingPartnerId());
        $this->assertSame($partner->id, $this->staffFor($partner)->workingPartnerId());
        $this->assertNull($this->staffFor($partner, active: false)->workingPartnerId());
        $this->assertNull(User::factory()->create(['role' => 'customer'])->workingPartnerId());
    }
}
