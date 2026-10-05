<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Service;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class LesbuyPickupIntegrityTest extends TestCase
{
    private function payload(array $sources): array
    {
        Queue::fake();
        $this->actingAsRole('customer');
        $service = Service::where('code', 'LESBUY')->first() ?? Service::factory()->create(['code' => 'LESBUY']);
        return [
            'service_id' => $service->id,
            'payment_method' => 'cash',
            'estimated_distance_m' => 1000,
            'pickup' => ['address' => 'Selected buying point', 'lat' => 14.12345, 'lng' => 121.12345],
            'dropoff' => ['address' => 'Customer home', 'lat' => 14.125, 'lng' => 121.125],
            'items' => array_map(fn ($source) => ['source' => $source, 'name' => 'Purchase', 'quantity' => 1], $sources),
        ];
    }

    public function test_mixed_cart_is_rejected_before_creating_order_or_addresses(): void
    {
        $payload = $this->payload(['manual', 'store']);
        $this->postJson('/api/v1/orders', $payload)->assertUnprocessable()->assertJsonValidationErrors('items');
        $this->assertDatabaseCount('orders', 0);
        $this->assertDatabaseCount('addresses', 0);
    }

    public function test_single_pickup_orders_preserve_buying_point_and_distinct_dropoff(): void
    {
        foreach (['manual', 'store'] as $source) {
            $payload = $this->payload([$source]);
            $response = $this->postJson('/api/v1/orders', $payload)->assertCreated();
            $order = Order::findOrFail($response->json('data.id'));
            $this->assertSame('Selected buying point', $order->pickup_address);
            $this->assertEquals(14.12345, $order->pickup_lat);
            $this->assertEquals(121.12345, $order->pickup_lng);
            $this->assertSame('Customer home', $order->dropoff_address);
            $this->assertEquals(14.125, $order->dropoff_lat);
            $this->assertEquals(121.125, $order->dropoff_lng);
        }
    }

    public function test_assigned_rider_receives_the_saved_purchase_and_delivery_locations(): void
    {
        $payload = $this->payload(['manual']);
        $payload['meta'] = ['order_type' => 'lesbuy_manual', 'manual_pickup_source' => 'customer_pin'];
        $response = $this->postJson('/api/v1/orders', $payload)->assertCreated();
        $order = Order::findOrFail($response->json('data.id'));
        $driver = \App\Models\DriverProfile::factory()->create();
        $this->activatePartner($driver->user);
        $order->update(['driver_id' => $driver->id, 'status' => 'accepted']);
        $this->actingAs($driver->user, 'sanctum');
        $data = $this->getJson("/api/v1/orders/{$order->id}")->assertOk()->json('data');
        foreach (['pickup', 'dropoff'] as $location) {
            $this->assertSame($payload[$location]['address'], $data[$location.'_address']);
            $this->assertEquals($payload[$location]['lat'], $data[$location.'_lat']);
            $this->assertEquals($payload[$location]['lng'], $data[$location.'_lng']);
        }
        // Purchase pins must not silently become saved customer addresses.
        $this->assertDatabaseCount('addresses', 0);
    }

    public function test_manual_order_requires_both_addresses_and_both_pins(): void
    {
        foreach (['pickup', 'dropoff'] as $location) {
            foreach (['address', 'lat', 'lng'] as $field) {
                $payload = $this->payload(['manual']);
                unset($payload[$location][$field]);
                $this->postJson('/api/v1/orders', $payload)
                    ->assertUnprocessable()->assertJsonValidationErrors("{$location}.{$field}");
            }
        }
        $this->assertDatabaseCount('orders', 0);
    }
}
