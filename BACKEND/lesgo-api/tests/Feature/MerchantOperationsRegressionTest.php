<?php

namespace Tests\Feature;

use App\Models\MenuCategory;
use App\Models\MenuItem;
use App\Models\Partner;
use App\Models\PartnerStaff;
use App\Models\User;
use App\Services\RegistrationFeeService;
use Tests\TestCase;

class MerchantOperationsRegressionTest extends TestCase
{
    private function merchant(): Partner
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'active']);
        $fee = RegistrationFeeService::ensurePaymentRecord($owner);
        $fee->update(['payment_status' => 'waived', 'waived_at' => now(), 'application_status' => 'approved', 'is_active' => true]);

        return $partner;
    }

    private function category(Partner $partner, bool $active = true): MenuCategory
    {
        return MenuCategory::create(['partner_id' => $partner->id, 'name' => 'Meals', 'is_active' => $active]);
    }

    private function item(MenuCategory $category, bool $available): MenuItem
    {
        return MenuItem::create([
            'partner_id' => $category->partner_id, 'menu_category_id' => $category->id,
            'name' => 'Rice meal', 'price' => 100, 'is_available' => $available,
        ]);
    }

    public function test_owner_can_retrieve_sold_out_items_and_hidden_categories(): void
    {
        $partner = $this->merchant();
        $category = $this->category($partner, false);
        $item = $this->item($category, false);
        $this->actingAs($partner->user, 'sanctum')
            ->getJson("/api/v1/partners/{$partner->id}/merchant-menu")
            ->assertOk()->assertJsonPath('data.categories.0.id', $category->id)
            ->assertJsonPath('data.categories.0.available_items.0.id', $item->id)
            ->assertJsonPath('data.categories.0.available_items.0.is_available', false);
        $this->getJson("/api/v1/partners/{$partner->id}/menu-items")
            ->assertOk()->assertJsonPath('data.0.id', $item->id);
    }

    public function test_customer_cannot_read_private_inventory_but_public_menu_still_hides_sold_out_items(): void
    {
        $partner = $this->merchant();
        $category = $this->category($partner);
        $this->item($category, false);
        $this->actingAs(User::factory()->create(['role' => 'customer']), 'sanctum');
        $this->getJson("/api/v1/partners/{$partner->id}/merchant-menu")->assertForbidden();
        $this->getJson("/api/v1/partners/{$partner->id}/menu-items")->assertForbidden();
        $this->getJson("/api/v1/partners/{$partner->id}/menu")
            ->assertOk()->assertJsonCount(0, 'data.categories.0.available_items');
    }

    public function test_empty_category_deletion_succeeds_instead_of_throwing_a_missing_relationship_error(): void
    {
        $partner = $this->merchant();
        $category = $this->category($partner);
        $this->actingAs($partner->user, 'sanctum')
            ->deleteJson("/api/v1/menu-categories/{$category->id}")->assertOk();
        $this->assertDatabaseMissing('menu_categories', ['id' => $category->id]);
    }

    public function test_category_with_hidden_items_cannot_be_deleted(): void
    {
        $partner = $this->merchant();
        $category = $this->category($partner);
        $this->item($category, false);
        $this->actingAs($partner->user, 'sanctum')
            ->deleteJson("/api/v1/menu-categories/{$category->id}")->assertStatus(400);
        $this->assertDatabaseHas('menu_categories', ['id' => $category->id]);
    }

    public function test_staff_details_are_private_to_store_owner_and_admin(): void
    {
        $partner = $this->merchant();
        $staffUser = User::factory()->create(['role' => 'partner_staff']);
        $staff = PartnerStaff::create(['partner_id' => $partner->id, 'user_id' => $staffUser->id, 'role' => 'cook']);
        $this->actingAs(User::factory()->create(['role' => 'customer']), 'sanctum');
        $this->getJson("/api/v1/partners/{$partner->id}/staff")->assertForbidden();
        $this->getJson("/api/v1/partners/{$partner->id}/staff/{$staff->id}")->assertForbidden();
        $this->actingAs($partner->user, 'sanctum')
            ->getJson("/api/v1/partners/{$partner->id}/staff")
            ->assertOk()->assertJsonPath('data.0.email', $staffUser->email);
    }
}
