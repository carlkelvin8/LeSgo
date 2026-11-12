<?php

namespace Tests\Feature;

use App\Models\MenuCategory;
use App\Models\MenuItem;
use App\Models\Partner;
use App\Models\User;
use App\Services\RegistrationFeeService;
use Tests\TestCase;

/**
 * The merchant app keeps stock inside options._inventory (see
 * merchant_item_inventory_utils.dart). The API must store it, otherwise a
 * merchant who sets "10 in stock" silently loses it.
 */
class MerchantMenuInventoryTest extends TestCase
{
    private function merchant(): Partner
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'active']);
        $fee = RegistrationFeeService::ensurePaymentRecord($owner);
        $fee->update(['payment_status' => 'waived', 'waived_at' => now(), 'application_status' => 'approved', 'is_active' => true]);

        return $partner;
    }

    private function item(Partner $partner): MenuItem
    {
        $category = MenuCategory::create(['partner_id' => $partner->id, 'name' => 'Meals', 'is_active' => true]);

        return MenuItem::create([
            'partner_id' => $partner->id, 'menu_category_id' => $category->id,
            'name' => 'hshaha', 'price' => 100, 'is_available' => true,
        ]);
    }

    private function inventory(int $stock = 10): array
    {
        return ['stock' => $stock, 'track_stock' => true, 'auto_hide_when_empty' => true];
    }

    public function test_update_keeps_the_inventory_block_in_options(): void
    {
        $partner = $this->merchant();
        $item = $this->item($partner);

        $this->actingAs($partner->user, 'sanctum')
            ->patchJson("/api/v1/menu-items/{$item->id}", ['options' => ['_inventory' => $this->inventory(10)]])
            ->assertOk();

        $this->assertSame(10, $item->fresh()->options['_inventory']['stock']);
        $this->assertTrue($item->fresh()->options['_inventory']['track_stock']);
    }

    public function test_update_keeps_sizes_and_inventory_together(): void
    {
        $partner = $this->merchant();
        $item = $this->item($partner);

        $this->actingAs($partner->user, 'sanctum')
            ->patchJson("/api/v1/menu-items/{$item->id}", ['options' => [
                'sizes' => [['label' => 'Large', 'price' => 20]],
                '_inventory' => $this->inventory(3),
            ]])
            ->assertOk();

        $options = $item->fresh()->options;
        $this->assertSame('Large', $options['sizes'][0]['label']);
        $this->assertSame(3, $options['_inventory']['stock']);
    }

    public function test_create_keeps_the_inventory_block_in_options(): void
    {
        $partner = $this->merchant();
        $category = MenuCategory::create(['partner_id' => $partner->id, 'name' => 'Meals', 'is_active' => true]);

        $id = $this->actingAs($partner->user, 'sanctum')
            ->postJson("/api/v1/partners/{$partner->id}/menu-items", [
                'menu_category_id' => $category->id, 'name' => 'Rice meal', 'price' => 50,
                'options' => ['_inventory' => $this->inventory(7)],
            ])
            ->assertCreated()
            ->json('data.id');

        $this->assertSame(7, MenuItem::findOrFail($id)->options['_inventory']['stock']);
    }

    public function test_inventory_values_are_validated(): void
    {
        $partner = $this->merchant();
        $item = $this->item($partner);

        $this->actingAs($partner->user, 'sanctum')
            ->patchJson("/api/v1/menu-items/{$item->id}", ['options' => ['_inventory' => ['stock' => -4, 'track_stock' => true]]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['options._inventory.stock']);
    }
}
