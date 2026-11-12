<?php

namespace Tests\Feature;

use App\Models\MenuCategory;
use App\Models\MenuItem;
use App\Models\Partner;
use App\Models\Service;
use App\Models\User;
use App\Services\RegistrationFeeService;
use Tests\TestCase;

/**
 * The merchant app's "Book" cart orders from the merchant's own menu. LesEat
 * orders are priced and validated against the menu on the server, so every
 * line must carry the menu_item_id it was added from.
 */
class MerchantSelfOrderTest extends TestCase
{
    private function merchant(): Partner
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'active', 'is_open' => true]);
        $fee = RegistrationFeeService::ensurePaymentRecord($owner);
        $fee->update(['payment_status' => 'waived', 'waived_at' => now(), 'application_status' => 'approved', 'is_active' => true]);

        return $partner;
    }

    private function menuItem(Partner $partner, float $price = 100): MenuItem
    {
        $category = MenuCategory::create(['partner_id' => $partner->id, 'name' => 'Meals', 'is_active' => true]);

        return MenuItem::create([
            'partner_id' => $partner->id, 'menu_category_id' => $category->id,
            'name' => 'hshaha', 'price' => $price, 'is_available' => true,
        ]);
    }

    /** Same shape as RIDERSIDE cart_checkout_provider.dart. */
    private function payload(Partner $partner, array $item): array
    {
        $service = Service::query()->where('code', 'LESEAT')->first()
            ?? Service::factory()->create(['code' => 'LESEAT']);

        return [
            'service_id' => $service->id,
            'partner_id' => $partner->id,
            'estimated_distance_m' => 3000,
            'payment_method' => 'cash',
            'notes' => 'Merchant self-order from app cart',
            'pickup' => ['address' => 'Store', 'lat' => 14.5995, 'lng' => 120.9842, 'contact_name' => 'Owner', 'contact_phone' => '+639171234567'],
            'dropoff' => ['address' => 'Home', 'lat' => 14.6090, 'lng' => 121.0000, 'contact_name' => 'Owner', 'contact_phone' => '+639171234567'],
            'items' => [$item],
        ];
    }

    public function test_cart_line_with_menu_item_id_creates_the_order(): void
    {
        $partner = $this->merchant();
        $menuItem = $this->menuItem($partner);

        $this->actingAs($partner->user, 'sanctum')
            ->postJson('/api/v1/orders', $this->payload($partner, [
                'name' => 'hshaha', 'quantity' => 2, 'estimated_price' => 100.0,
                'notes' => 'Regular', 'menu_item_id' => $menuItem->id,
            ]))
            ->assertCreated();
    }

    public function test_cart_line_without_menu_item_id_is_rejected(): void
    {
        $partner = $this->merchant();
        $this->menuItem($partner);

        $this->actingAs($partner->user, 'sanctum')
            ->postJson('/api/v1/orders', $this->payload($partner, [
                'name' => 'hshaha', 'quantity' => 1, 'estimated_price' => 100.0, 'notes' => 'Regular',
            ]))
            ->assertStatus(422)
            ->assertJsonPath('message', 'A menu item is no longer available. Refresh the cart and try again.');
    }

    public function test_rider_gets_the_store_phone_instead_of_the_apps_placeholder(): void
    {
        $partner = $this->merchant();
        $partner->update(['support_phone' => '09171234567']);
        $menuItem = $this->menuItem($partner);
        $payload = $this->payload($partner, [
            'name' => 'hshaha', 'quantity' => 1, 'estimated_price' => 100.0,
            'notes' => 'Regular', 'menu_item_id' => $menuItem->id,
        ]);
        $payload['pickup']['contact_phone'] = '+639123456789';

        $id = $this->actingAs(User::factory()->create(['role' => 'customer']), 'sanctum')
            ->postJson('/api/v1/orders', $payload)
            ->assertCreated()
            ->json('data.id');

        $this->assertSame('09171234567', \App\Models\Order::findOrFail($id)->pickup_contact_phone);
    }

    public function test_stale_cart_price_is_rejected_with_a_price_message(): void
    {
        $partner = $this->merchant();
        $menuItem = $this->menuItem($partner, 100);

        $this->actingAs($partner->user, 'sanctum')
            ->postJson('/api/v1/orders', $this->payload($partner, [
                'name' => 'hshaha', 'quantity' => 1, 'estimated_price' => 10.0,
                'notes' => 'Regular', 'menu_item_id' => $menuItem->id,
            ]))
            ->assertStatus(409);
    }
}
