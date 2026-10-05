<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProofImageAuthorizationTest extends TestCase
{
    public function test_proof_image_is_private_to_the_order_customer(): void
    {
        Storage::fake('public');
        $customer = User::factory()->create(['role' => 'customer']);
        $order = Order::factory()->completed()->create(['customer_id' => $customer->id]);
        Storage::disk('public')->put("proof_images/{$order->id}/delivery.jpg", 'image-bytes');

        $this->getJson("/api/v1/proof-images/{$order->id}/delivery.jpg")->assertUnauthorized();
        $this->actingAs(User::factory()->create(['role' => 'customer']), 'sanctum')
            ->getJson("/api/v1/proof-images/{$order->id}/delivery.jpg")->assertForbidden();

        $response = $this->actingAs($customer, 'sanctum')
            ->getJson("/api/v1/proof-images/{$order->id}/delivery.jpg")
            ->assertOk();
        $this->assertStringContainsString('private', $response->headers->get('Cache-Control'));
        $this->assertStringContainsString('no-store', $response->headers->get('Cache-Control'));
    }
}
