<?php

namespace Tests\Feature;

use App\Jobs\AutoAssignDriverJob;
use App\Models\DriverProfile;
use App\Models\Order;
use App\Models\Service;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class LesrideFeatureTest extends TestCase
{
    use RefreshDatabase;

    private Service $service;

    private User $customer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->service = Service::factory()->create([
            'code' => 'LESRIDE',
            'name' => 'LesRide',
            'base_fare' => 60,
            'per_km_rate' => 15,
            'minimum_fare' => 60,
            'is_active' => true,
        ]);
        $this->customer = $this->actingAsRole('customer');
    }

    private function payload(int $distanceM, string $vehicleType): array
    {
        return [
            'service_id' => $this->service->id,
            'estimated_distance_m' => $distanceM,
            'vehicle_type' => $vehicleType,
            'payment_method' => 'cash',
            'pickup' => [
                'address' => 'Pickup',
                'lat' => 8.4542,
                'lng' => 124.6319,
            ],
            'dropoff' => [
                'address' => 'Dropoff',
                'lat' => 8.4700,
                'lng' => 124.6500,
            ],
        ];
    }

    public function test_tricycle_estimate_uses_the_lesride_fare_matrix(): void
    {
        $payload = $this->payload(5500, 'tricycle');
        $payload['estimated_weight_kg'] = 25;
        $response = $this->postJson(
            '/api/v1/orders/estimate',
            $payload
        );

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.fare_breakdown.base_fare', 60)
            ->assertJsonPath('data.fare_breakdown.distance_fare', 37.5)
            ->assertJsonPath('data.fare_breakdown.weight_surcharge', 0)
            ->assertJsonPath('data.estimated_fare', 97.5)
            ->assertJsonPath('data.payment_methods.5', 'xendit');
    }

    public function test_created_lesride_order_persists_tricycle_and_server_calculated_fare(): void
    {
        Queue::fake();
        $payload = $this->payload(4000, 'tricycle');
        $payload['meta'] = ['vehicle_type' => 'sedan'];
        $payload['estimated_weight_kg'] = 25;

        $response = $this->postJson(
            '/api/v1/orders',
            $payload
        );

        $response->assertCreated()
            ->assertJsonPath('data.vehicle_type', 'tricycle')
            ->assertJsonPath('data.meta.vehicle_type', 'tricycle')
            ->assertJsonPath('data.estimated_fare', '75.00');

        $this->assertDatabaseHas('orders', [
            'service_id' => $this->service->id,
            'vehicle_type' => 'tricycle',
            'estimated_fare' => 75,
        ]);
        Queue::assertPushed(AutoAssignDriverJob::class);
    }

    public function test_locked_lesride_vehicle_options_are_rejected(): void
    {
        $this->postJson(
            '/api/v1/orders/estimate',
            $this->payload(4000, 'sedan')
        )->assertStatus(422);

        $this->postJson(
            '/api/v1/orders',
            $this->payload(4000, 'seven_seater')
        )->assertStatus(422);
    }

    public function test_lesride_requires_the_available_tricycle_option(): void
    {
        $payload = $this->payload(4000, 'tricycle');
        unset($payload['vehicle_type']);

        $this->postJson('/api/v1/orders/estimate', $payload)
            ->assertStatus(422);

        $this->postJson('/api/v1/orders', $payload)
            ->assertStatus(422);
    }

    public function test_tricycle_option_is_scoped_to_lesride(): void
    {
        $lesgo = Service::factory()->create([
            'code' => 'LESGO',
            'is_active' => true,
        ]);
        $payload = $this->payload(4000, 'tricycle');
        $payload['service_id'] = $lesgo->id;

        $this->postJson('/api/v1/orders/estimate', $payload)
            ->assertStatus(422)
            ->assertJsonPath('message', 'The Tricycle option is only available for LesRide.');

        $this->postJson('/api/v1/orders', $payload)
            ->assertStatus(422)
            ->assertJsonPath('message', 'The Tricycle option is only available for LesRide.');
    }

    public function test_lesride_rejects_routes_above_thirty_kilometers(): void
    {
        $payload = $this->payload(30001, 'tricycle');

        $this->postJson('/api/v1/orders/estimate', $payload)
            ->assertStatus(422)
            ->assertJsonPath('message', 'LesRide is currently limited to 30km.');

        $this->postJson('/api/v1/orders', $payload)
            ->assertStatus(422);
    }

    public function test_lesride_rejects_a_distance_that_is_shorter_than_the_selected_locations(): void
    {
        $payload = $this->payload(500, 'tricycle');

        $this->postJson('/api/v1/orders/estimate', $payload)
            ->assertStatus(422)
            ->assertJsonPath('message', 'The route distance does not match the selected locations.');

        $this->postJson('/api/v1/orders', $payload)
            ->assertStatus(422)
            ->assertJsonPath('message', 'The route distance does not match the selected locations.');
    }

    public function test_lesride_rejects_identical_pickup_and_destination(): void
    {
        $payload = $this->payload(1000, 'tricycle');
        $payload['dropoff']['lat'] = $payload['pickup']['lat'];
        $payload['dropoff']['lng'] = $payload['pickup']['lng'];

        $this->postJson('/api/v1/orders/estimate', $payload)
            ->assertStatus(422)
            ->assertJsonPath('message', 'Pickup and destination must be different.');

        $this->postJson('/api/v1/orders', $payload)
            ->assertStatus(422)
            ->assertJsonPath('message', 'Pickup and destination must be different.');
    }

    public function test_reorder_uses_the_current_tricycle_option_and_fare(): void
    {
        Queue::fake();
        $oldOrder = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'completed',
            'completed_at' => now(),
            'vehicle_type' => 'sedan',
            'estimated_distance_m' => 4000,
            'estimated_fare' => 30,
            'meta' => ['vehicle_type' => 'sedan'],
        ]);

        $this->postJson("/api/v1/orders/{$oldOrder->id}/reorder")
            ->assertCreated()
            ->assertJsonPath('data.vehicle_type', 'tricycle')
            ->assertJsonPath('data.meta.vehicle_type', 'tricycle')
            ->assertJsonPath('data.estimated_fare', '75.00');
    }

    public function test_reorder_is_blocked_when_lesride_is_inactive(): void
    {
        $oldOrder = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'completed',
            'completed_at' => now(),
            'vehicle_type' => 'tricycle',
            'estimated_distance_m' => 4000,
            'estimated_fare' => 75,
        ]);
        $this->service->update(['is_active' => false]);

        $this->postJson("/api/v1/orders/{$oldOrder->id}/reorder")
            ->assertStatus(422)
            ->assertJsonPath('message', 'This service is currently unavailable.');
    }

    public function test_legacy_lesride_route_above_thirty_kilometers_cannot_be_reordered(): void
    {
        $oldOrder = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'status' => 'completed',
            'completed_at' => now(),
            'vehicle_type' => 'tricycle',
            'estimated_distance_m' => 31000,
            'estimated_fare' => 480,
        ]);

        $this->postJson("/api/v1/orders/{$oldOrder->id}/reorder")
            ->assertStatus(422)
            ->assertJsonPath('message', 'This LesRide route can no longer be reordered.');
    }

    public function test_online_lesride_order_is_dispatchable_only_after_payment(): void
    {
        Queue::fake();
        $payload = $this->payload(4000, 'tricycle');
        $payload['payment_method'] = 'xendit';

        $response = $this->postJson('/api/v1/orders', $payload)
            ->assertCreated()
            ->assertJsonPath('data.payment_method', 'xendit')
            ->assertJsonPath('data.payment_status', 'pending');

        $order = Order::findOrFail($response->json('data.id'));
        Queue::assertNotPushed(AutoAssignDriverJob::class);

        $driver = User::factory()->create(['role' => 'driver']);
        DriverProfile::factory()->create([
            'user_id' => $driver->id,
            'status' => 'active',
            'vehicle_type' => 'tricycle',
        ]);
        $driver->wallet()->create(['balance' => 1000]);
        $this->activatePartner($driver);
        $this->actingAs($driver, 'sanctum');

        $ordersResponse = $this->getJson('/api/v1/orders')->assertOk();
        $orders = collect($ordersResponse->json('data.data') ?? $ordersResponse->json('data'));
        $this->assertNull($orders->firstWhere('id', $order->id));

        $this->patchJson("/api/v1/orders/{$order->id}/status", [
            'status' => 'accepted',
        ])->assertStatus(403)
            ->assertJsonPath('message', 'This order is not available for driver acceptance.');

        $order->update(['payment_status' => 'paid']);

        $ordersResponse = $this->getJson('/api/v1/orders')->assertOk();
        $orders = collect($ordersResponse->json('data.data') ?? $ordersResponse->json('data'));
        $this->assertNotNull($orders->firstWhere('id', $order->id));

        $this->patchJson("/api/v1/orders/{$order->id}/status", [
            'status' => 'accepted',
        ])->assertOk()
            ->assertJsonPath('data.driver_id', $driver->driverProfile->id);
    }

    public function test_actual_distance_recalculation_uses_the_same_lesride_matrix(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'service_id' => $this->service->id,
            'vehicle_type' => 'tricycle',
            'estimated_distance_m' => 3000,
            'estimated_fare' => 60,
        ]);
        $this->actingAsRole('admin');

        $this->patchJson("/api/v1/orders/{$order->id}/status", [
            'actual_distance_m' => 5500,
        ])->assertOk()
            ->assertJsonPath('data.actual_fare', '97.50');
    }

    public function test_lesride_rollout_does_not_change_existing_service_actual_fares(): void
    {
        $lesgo = Service::factory()->create([
            'code' => 'LESGO',
            'base_fare' => 75,
            'per_km_rate' => 20,
            'minimum_fare' => 75,
            'is_active' => true,
        ]);
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'service_id' => $lesgo->id,
            'estimated_weight_kg' => 20,
            'estimated_distance_m' => 3000,
            'estimated_fare' => 40,
        ]);
        $this->actingAsRole('admin');

        $this->patchJson("/api/v1/orders/{$order->id}/status", [
            'actual_distance_m' => 5000,
        ])->assertOk()
            ->assertJsonPath('data.actual_fare', '59.00');
    }
}
