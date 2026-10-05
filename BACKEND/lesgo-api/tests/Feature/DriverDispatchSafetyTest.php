<?php

namespace Tests\Feature;

use App\Events\OrderStatusUpdated;
use App\Jobs\AutoAssignDriverJob;
use App\Jobs\AutoCancelStaleOrdersJob;
use App\Jobs\NotifyDriverAssignedJob;
use App\Jobs\NotifyNearbyDriversNewOrderJob;
use App\Models\DriverLocation;
use App\Models\DriverProfile;
use App\Models\Order;
use App\Models\Payment;
use App\Models\Service;
use App\Models\User;
use App\Services\DriverAssignmentService;
use App\Services\OrderDriverWalletService;
use App\Services\WalletService;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class DriverDispatchSafetyTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $connection = \Illuminate\Support\Facades\DB::connection();
        if ($connection->getDriverName() === 'sqlite') {
            // Some Windows SQLite builds omit optional SQL math functions.
            foreach (['acos' => 'acos', 'cos' => 'cos', 'sin' => 'sin', 'radians' => 'deg2rad'] as $sql => $php) {
                $connection->getPdo()->sqliteCreateFunction($sql, $php, 1);
            }
        }
    }

    public function test_order_driver_relation_resolves_driver_profile_to_user(): void
    {
        $driver = User::factory()->driver()->create();
        $profile = DriverProfile::factory()->create(['user_id' => $driver->id]);
        $order = Order::factory()->create(['driver_id' => $profile->id]);

        $this->assertTrue($order->driver->is($driver));
    }

    public function test_dispatch_scope_matches_domain_rules(): void
    {
        $customer = User::factory()->create();
        $service = Service::factory()->create();

        $available = Order::factory()->create([
            'customer_id' => $customer->id,
            'service_id' => $service->id,
            'payment_method' => 'cash',
        ]);
        Order::factory()->create([
            'customer_id' => $customer->id,
            'service_id' => $service->id,
            'payment_method' => 'xendit',
            'payment_status' => 'pending',
        ]);
        Order::factory()->create([
            'customer_id' => $customer->id,
            'service_id' => $service->id,
            'scheduled_at' => now()->addHour(),
        ]);
        Order::factory()->create([
            'customer_id' => $customer->id,
            'service_id' => $service->id,
            'meta' => ['manual_assignment' => true],
        ]);

        $dispatchableIds = Order::query()
            ->dispatchableToDrivers()
            ->pluck('id');

        $this->assertSame([$available->id], $dispatchableIds->all());
    }

    public function test_latest_driver_location_controls_proximity(): void
    {
        $driver = $this->createAvailableDriver(latitude: 8.4542, longitude: 124.6319);
        DriverLocation::create([
            'driver_id' => $driver->id,
            'latitude' => 9.0,
            'longitude' => 125.0,
            'status' => 'online',
            'recorded_at' => now(),
        ]);

        $isNearby = User::query()
            ->whereKey($driver->id)
            ->whereHas('latestDriverLocation', function ($query) {
                $query->online()->recent()->nearby(8.4542, 124.6319, 10);
            })
            ->exists();

        $this->assertFalse($isNearby);
    }

    public function test_auto_assignment_skips_busy_driver_and_charges_selected_driver_once(): void
    {
        Queue::fake();
        $customer = User::factory()->create();
        $service = Service::factory()->create(['code' => 'LESRIDE']);
        $busyDriver = $this->createAvailableDriver(
            latitude: 8.4542,
            longitude: 124.6319,
            rating: 5.0
        );
        $freeDriver = $this->createAvailableDriver(
            latitude: 8.4550,
            longitude: 124.6325,
            rating: 4.0
        );

        Order::factory()->create([
            'customer_id' => $customer->id,
            'service_id' => $service->id,
            'driver_id' => $busyDriver->driverProfile->id,
            'status' => 'in_progress',
        ]);
        $target = Order::factory()->create([
            'customer_id' => $customer->id,
            'service_id' => $service->id,
            'pickup_lat' => 8.4542,
            'pickup_lng' => 124.6319,
            'vehicle_type' => 'tricycle',
            'estimated_fare' => 100,
            'payment_method' => 'cash',
            'status' => 'pending',
        ]);

        $assigned = app(DriverAssignmentService::class)->autoAssignDriver($target);

        $this->assertNotNull($assigned);
        $this->assertSame($freeDriver->id, $assigned->id);
        $this->assertSame($freeDriver->driverProfile->id, $target->fresh()->driver_id);
        $this->assertSame('accepted', $target->fresh()->status);
        $this->assertSame(980.0, (float) $freeDriver->wallet()->first()->balance);
        $this->assertDatabaseCount('wallet_transactions', 1);
        Queue::assertPushed(NotifyDriverAssignedJob::class, 1);
    }

    public function test_notification_job_rechecks_dispatch_eligibility(): void
    {
        $driver = $this->createAvailableDriver(latitude: 8.4542, longitude: 124.6319);
        $order = Order::factory()->create([
            'pickup_lat' => 8.4542,
            'pickup_lng' => 124.6319,
            'vehicle_type' => 'tricycle',
            'meta' => ['manual_assignment' => true],
        ]);

        (new NotifyNearbyDriversNewOrderJob($order))->handle();

        $this->assertDatabaseMissing('notifications', [
            'user_id' => $driver->id,
        ]);
    }

    public function test_incompatible_driver_cannot_discover_or_accept_order(): void
    {
        $driver = $this->createAvailableDriver(latitude: 8.4542, longitude: 124.6319);
        $driver->driverProfile->update(['vehicle_type' => 'car']);
        $order = Order::factory()->create([
            'pickup_lat' => 8.4542,
            'pickup_lng' => 124.6319,
            'vehicle_type' => 'tricycle',
        ]);
        $this->actingAs($driver, 'sanctum');

        $response = $this->getJson('/api/v1/orders')->assertOk();
        $orders = collect($response->json('data.data') ?? $response->json('data'));
        $this->assertNull($orders->firstWhere('id', $order->id));

        $this->patchJson("/api/v1/orders/{$order->id}/status", [
            'status' => 'accepted',
        ])->assertForbidden()
            ->assertJsonPath('message', 'This order requires a different vehicle type.');

        $this->assertNull($order->fresh()->driver_id);
    }

    public function test_busy_driver_cannot_accept_a_second_order_directly(): void
    {
        $driver = $this->createAvailableDriver(latitude: 8.4542, longitude: 124.6319);
        Order::factory()->create([
            'driver_id' => $driver->driverProfile->id,
            'status' => 'picked_up',
        ]);
        $target = Order::factory()->create(['vehicle_type' => 'tricycle']);
        $this->actingAs($driver, 'sanctum');

        $this->patchJson("/api/v1/orders/{$target->id}/status", [
            'status' => 'accepted',
        ])->assertConflict()
            ->assertJsonPath(
                'message',
                'Complete your active delivery before accepting another order.'
            );

        $this->assertNull($target->fresh()->driver_id);
        $this->assertSame(1000.0, (float) $driver->wallet()->first()->balance);
    }

    public function test_due_scheduled_order_uses_shared_dispatch_pipeline(): void
    {
        Queue::fake();
        $order = Order::factory()->create([
            'status' => 'scheduled',
            'scheduled_at' => now()->subMinute(),
            'scheduled_delivery_time' => null,
        ]);

        $this->artisan('orders:process-scheduled')->assertSuccessful();

        $this->assertSame('pending', $order->fresh()->status);
        Queue::assertPushed(NotifyNearbyDriversNewOrderJob::class, 1);
        Queue::assertPushed(AutoAssignDriverJob::class, 1);
    }

    public function test_stale_cleanup_only_cancels_orders_that_are_still_dispatchable(): void
    {
        Event::fake([OrderStatusUpdated::class]);
        $staleCashOrder = Order::factory()->create([
            'created_at' => now()->subHour(),
        ]);
        $unpaidOnlineOrder = Order::factory()->create([
            'payment_method' => 'xendit',
            'payment_status' => 'pending',
            'created_at' => now()->subHour(),
        ]);
        $manualOrder = Order::factory()->create([
            'meta' => ['manual_assignment' => true],
            'created_at' => now()->subHour(),
        ]);

        (new AutoCancelStaleOrdersJob)->handle();

        $this->assertSame('cancelled', $staleCashOrder->fresh()->status);
        $this->assertSame('cancelled', $unpaidOnlineOrder->fresh()->status);
        $this->assertSame('failed', $unpaidOnlineOrder->fresh()->payment_status);
        $this->assertSame('pending', $manualOrder->fresh()->status);
        Event::assertDispatched(OrderStatusUpdated::class, function ($event) use ($staleCashOrder) {
            return $event->order->is($staleCashOrder)
                && $event->previousStatus === 'pending'
                && $event->newStatus === 'cancelled';
        });
        Event::assertDispatched(OrderStatusUpdated::class, function ($event) use ($unpaidOnlineOrder) {
            return $event->order->is($unpaidOnlineOrder)
                && $event->previousStatus === 'pending'
                && $event->newStatus === 'cancelled';
        });
        Event::assertDispatchedTimes(OrderStatusUpdated::class, 2);
    }

    public function test_stale_wallet_paid_order_is_refunded_before_auto_cancel(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $wallet = $user->wallet()->create(['balance' => 1000, 'currency' => 'PHP']);
        $order = Order::factory()->create([
            'customer_id' => $user->id,
            'estimated_fare' => 165,
            'payment_method' => 'wallet',
            'payment_status' => 'paid',
            'created_at' => now()->subHour(),
        ]);
        WalletService::debit($user, 165, 'Test checkout debit', Order::class, $order->id);
        $payment = Payment::create([
            'order_id' => $order->id,
            'customer_id' => $user->id,
            'amount' => 165,
            'currency' => 'PHP',
            'method' => 'wallet',
            'status' => 'paid',
            'provider' => 'lespay',
        ]);

        (new AutoCancelStaleOrdersJob)->handle();

        $this->assertSame('cancelled', $order->fresh()->status);
        $this->assertSame('refunded', $order->fresh()->payment_status);
        $this->assertSame(1000.0, (float) $wallet->fresh()->balance);
        $this->assertSame('refunded', $payment->fresh()->status);
    }

    public function test_driver_wallet_charge_can_be_refunded_and_recharged_on_reassignment(): void
    {
        $firstDriver = User::factory()->driver()->create();
        $secondDriver = User::factory()->driver()->create();
        $firstWallet = $firstDriver->wallet()->create(['balance' => 100, 'currency' => 'PHP']);
        $secondWallet = $secondDriver->wallet()->create(['balance' => 100, 'currency' => 'PHP']);
        $order = Order::factory()->create(['estimated_fare' => 100]);

        OrderDriverWalletService::chargeDriverOnAccept($firstDriver, $order);
        $order->save();
        $this->assertSame(80.0, (float) $firstWallet->fresh()->balance);

        OrderDriverWalletService::refundDriverOnCancel($order);
        $this->assertSame(100.0, (float) $firstWallet->fresh()->balance);

        $order = $order->fresh();
        OrderDriverWalletService::chargeDriverOnAccept($secondDriver, $order);
        $order->save();
        $this->assertSame(80.0, (float) $secondWallet->fresh()->balance);

        OrderDriverWalletService::refundDriverOnCancel($order);
        $this->assertSame(100.0, (float) $secondWallet->fresh()->balance);
    }

    private function createAvailableDriver(
        float $latitude,
        float $longitude,
        float $rating = 4.5,
    ): User {
        $driver = User::factory()->driver()->create();
        DriverProfile::factory()->create([
            'user_id' => $driver->id,
            'status' => 'active',
            'rating' => $rating,
            'vehicle_type' => 'tricycle',
        ]);
        $driver->wallet()->create(['balance' => 1000, 'currency' => 'PHP']);
        DriverLocation::create([
            'driver_id' => $driver->id,
            'latitude' => $latitude,
            'longitude' => $longitude,
            'status' => 'online',
            'recorded_at' => now()->subMinute(),
        ]);

        $this->activatePartner($driver);
        return $driver->fresh(['driverProfile', 'wallet', 'latestDriverLocation']);
    }
}
