<?php

namespace Tests\Feature;

use App\Jobs\AutoAssignDriverJob;
use App\Jobs\NotifyNearbyDriversNewOrderJob;
use App\Models\Order;
use App\Models\Service;
use App\Models\User;
use App\Services\OrderWalletPaymentService;
use App\Services\VoucherService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class OrderTest extends TestCase
{
    use RefreshDatabase;

    private function makeOrderPayload(int $serviceId): array
    {
        return [
            'service_id' => $serviceId,
            'pickup' => ['address' => '123 Rizal St', 'lat' => 14.5995, 'lng' => 120.9842],
            'dropoff' => ['address' => '456 Mabini Ave', 'lat' => 14.6090, 'lng' => 121.0000],
            'estimated_distance_m' => 5000,
            'payment_method' => 'cash',
        ];
    }

    // ── Create Order ──────────────────────────────────────────────────────────

    public function test_customer_can_create_order(): void
    {
        Queue::fake();
        $service = Service::factory()->create(['code' => 'LESGO']);
        $this->actingAsRole('customer');

        $response = $this->postJson('/api/v1/orders', $this->makeOrderPayload($service->id));

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['id', 'status', 'estimated_fare']]);

        $this->assertDatabaseHas('orders', ['service_id' => $service->id, 'status' => 'pending']);
    }

    public function test_client_order_totals_cannot_override_server_payable_amount(): void
    {
        Queue::fake();
        $service = Service::factory()->create(['code' => 'LESGO']);
        $this->actingAsRole('customer');
        $payload = $this->makeOrderPayload($service->id);
        $payload['meta'] = [
            'grand_total' => 0.01,
            'total' => 0.01,
            'subtotal' => 0.01,
            'delivery_fee' => 0,
            'discount' => 0,
        ];

        $response = $this->postJson('/api/v1/orders', $payload)->assertCreated();
        $order = Order::findOrFail($response->json('data.id'));

        $this->assertNotSame(0.01, (float) $order->meta['grand_total']);
        $this->assertEquals((float) $order->estimated_fare, (float) $order->meta['grand_total']);
        $this->assertEquals((float) $order->estimated_fare, OrderWalletPaymentService::resolvePayableAmount($order));
    }

    public function test_payable_amount_ignores_later_meta_tampering_and_includes_server_order_items(): void
    {
        $service = Service::factory()->create(['code' => 'LESEAT']);
        $order = Order::factory()->create([
            'service_id' => $service->id,
            'estimated_fare' => 65,
            'discount_amount' => 10,
            'meta' => ['grand_total' => 0.01, 'total' => 0.01],
        ]);
        $order->lesbuyItems()->create([
            'name' => 'Meal',
            'quantity' => 2,
            'estimated_price' => 50,
            'actual_price' => null,
            'status' => 'pending',
        ]);

        $this->assertEquals(155, OrderWalletPaymentService::resolvePayableAmount($order));
    }

    public function test_first_order_voucher_does_not_count_the_order_being_created(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $service = Service::factory()->create(['code' => 'LESEAT']);
        $order = Order::factory()->create([
            'customer_id' => $user->id,
            'service_id' => $service->id,
            'voucher_code' => 'WELCOME10',
            'estimated_fare' => 115,
            'meta' => ['subtotal' => 100, 'delivery_fee' => 15],
        ]);

        $result = app(VoucherService::class)->applyVoucher($order, 'WELCOME10');

        $this->assertTrue($result['valid'], $result['error'] ?? 'Voucher unexpectedly rejected');
        $this->assertEquals(11.5, (float) $result['discount_amount']);
    }

    public function test_scheduled_delivery_time_is_persisted_and_not_dispatched_early(): void
    {
        Queue::fake();
        $service = Service::factory()->create(['code' => 'LESGO']);
        $this->actingAsRole('customer');
        $scheduledFor = now()->addHour()->startOfSecond();
        $payload = $this->makeOrderPayload($service->id);
        $payload['scheduled_delivery_time'] = $scheduledFor->toISOString();

        $response = $this->postJson('/api/v1/orders', $payload)
            ->assertCreated()
            ->assertJsonPath('data.status', 'scheduled');

        $order = Order::findOrFail($response->json('data.id'));
        $this->assertTrue($order->scheduled_delivery_time->equalTo($scheduledFor));
        Queue::assertNotPushed(NotifyNearbyDriversNewOrderJob::class);
        Queue::assertNotPushed(AutoAssignDriverJob::class);

        $this->travel(61)->minutes();
        $this->artisan('orders:process-scheduled')->assertSuccessful();
        $this->assertSame('pending', $order->fresh()->status);
        Queue::assertPushed(NotifyNearbyDriversNewOrderJob::class, 1);
        Queue::assertPushed(AutoAssignDriverJob::class, 1);
        $this->artisan('orders:process-scheduled')->assertSuccessful();
        Queue::assertPushed(NotifyNearbyDriversNewOrderJob::class, 1);
        $this->travelBack();
    }

    public function test_order_requires_authentication(): void
    {
        $service = Service::factory()->create();

        $this->postJson('/api/v1/orders', $this->makeOrderPayload($service->id))
            ->assertStatus(401);
    }

    public function test_order_requires_valid_service(): void
    {
        $this->actingAsRole('customer');

        $this->postJson('/api/v1/orders', $this->makeOrderPayload(99999))
            ->assertStatus(422);
    }

    public function test_order_requires_pickup_and_dropoff(): void
    {
        $service = Service::factory()->create();
        $this->actingAsRole('customer');

        $this->postJson('/api/v1/orders', [
            'service_id' => $service->id,
            'estimated_distance_m' => 5000,
        ])->assertStatus(422);
    }

    // ── List Orders ───────────────────────────────────────────────────────────

    public function test_customer_sees_only_own_orders(): void
    {
        $customer = $this->actingAsRole('customer');
        $other = User::factory()->create(['role' => 'customer']);
        $service = Service::factory()->create();

        Order::factory()->create(['customer_id' => $customer->id, 'service_id' => $service->id]);
        Order::factory()->create(['customer_id' => $other->id, 'service_id' => $service->id]);

        $response = $this->getJson('/api/v1/orders');

        $response->assertStatus(200);
        $this->assertPaginated($response);
        $this->assertCount(1, $response->json('data'));
    }

    public function test_admin_sees_all_orders(): void
    {
        $service = Service::factory()->create();
        $customer = User::factory()->create(['role' => 'customer']);

        Order::factory()->count(3)->create(['customer_id' => $customer->id, 'service_id' => $service->id]);

        $this->actingAsRole('admin');

        $response = $this->getJson('/api/v1/orders');
        $response->assertStatus(200);
        $this->assertCount(3, $response->json('data'));
    }

    public function test_orders_can_be_filtered_by_status(): void
    {
        $customer = $this->actingAsRole('customer');
        $service = Service::factory()->create();

        Order::factory()->create(['customer_id' => $customer->id, 'service_id' => $service->id, 'status' => 'pending']);
        Order::factory()->create(['customer_id' => $customer->id, 'service_id' => $service->id, 'status' => 'completed', 'completed_at' => now()]);

        $response = $this->getJson('/api/v1/orders?status=pending');
        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('pending', $response->json('data.0.status'));
    }

    // ── Show Order ────────────────────────────────────────────────────────────

    public function test_customer_can_view_own_order(): void
    {
        $customer = $this->actingAsRole('customer');
        $service = Service::factory()->create();
        $order = Order::factory()->create(['customer_id' => $customer->id, 'service_id' => $service->id]);

        $this->getJson("/api/v1/orders/{$order->id}")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $order->id);
    }

    public function test_customer_cannot_view_other_customers_order(): void
    {
        $this->actingAsRole('customer');
        $other = User::factory()->create(['role' => 'customer']);
        $service = Service::factory()->create();
        $order = Order::factory()->create(['customer_id' => $other->id, 'service_id' => $service->id]);

        $this->getJson("/api/v1/orders/{$order->id}")->assertStatus(403);
    }

    public function test_admin_can_view_any_order(): void
    {
        $this->actingAsRole('admin');
        $customer = User::factory()->create(['role' => 'customer']);
        $service = Service::factory()->create();
        $order = Order::factory()->create(['customer_id' => $customer->id, 'service_id' => $service->id]);

        $this->getJson("/api/v1/orders/{$order->id}")->assertStatus(200);
    }

    // ── Update Status ─────────────────────────────────────────────────────────

    public function test_customer_can_cancel_pending_order(): void
    {
        $customer = $this->actingAsRole('customer');
        $service = Service::factory()->create();
        $order = Order::factory()->create(['customer_id' => $customer->id, 'service_id' => $service->id, 'status' => 'pending']);

        $this->patchJson("/api/v1/orders/{$order->id}/status", [
            'status' => 'cancelled',
            'cancel_reason' => 'Changed my mind',
        ])->assertStatus(200)
            ->assertJsonPath('data.status', 'cancelled');
    }

    public function test_customer_cannot_cancel_completed_order(): void
    {
        $customer = $this->actingAsRole('customer');
        $service = Service::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'service_id' => $service->id,
            'status' => 'completed',
            'completed_at' => now(),
        ]);

        $this->patchJson("/api/v1/orders/{$order->id}/status", ['status' => 'cancelled'])
            ->assertStatus(403);
    }

    public function test_customer_cannot_cancel_order_after_delivery_is_in_progress(): void
    {
        $customer = $this->actingAsRole('customer');
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'status' => 'in_progress',
        ]);

        $this->patchJson("/api/v1/orders/{$order->id}/status", ['status' => 'cancelled'])
            ->assertForbidden();

        $this->assertSame('in_progress', $order->fresh()->status);
    }

    public function test_order_show_returns_404_for_nonexistent(): void
    {
        $this->actingAsRole('admin');
        $this->getJson('/api/v1/orders/99999')->assertStatus(404);
    }
}
