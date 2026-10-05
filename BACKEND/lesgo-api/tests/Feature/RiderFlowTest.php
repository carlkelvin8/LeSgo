<?php

namespace Tests\Feature;

use App\Models\DriverProfile;
use App\Models\Order;
use App\Models\Service;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * Complete rider flow integration test.
 * Tests the full lifecycle: register → login → load orders → accept → status transitions → complete.
 */
class RiderFlowTest extends TestCase
{
    use RefreshDatabase;

    private function payAndApprove(User $user): void
    {
        // Operational fixtures must satisfy the same fee gate as real accounts.
        $fee = \App\Services\RegistrationFeeService::ensurePaymentRecord($user);
        $fee->update(['payment_status' => 'paid', 'payment_date' => now()]);
        \App\Services\RegistrationFeeService::approveApplication($fee->fresh(), User::factory()->create(['role' => 'admin']));
    }

    private User $driver;

    private DriverProfile $driverProfile;

    private Service $service;

    private Order $order;

    protected function setUp(): void
    {
        parent::setUp();
        Queue::fake();

        $this->service = Service::factory()->create(['code' => 'LESGO', 'base_fare' => 40, 'per_km_rate' => 9.5]);

        // Create a driver user with active profile
        $this->driver = User::factory()->create(['role' => 'driver']);
        $this->driverProfile = DriverProfile::factory()->create([
            'user_id' => $this->driver->id,
            'status' => 'active',
            'rating' => 4.5,
            'package_tier' => 'basic',
        ]);

        $this->payAndApprove($this->driver);

        // Create a pending order (simulating customer booking)
        $customer = User::factory()->create(['role' => 'customer']);
        $this->order = Order::factory()->create([
            'customer_id' => $customer->id,
            'service_id' => $this->service->id,
            'status' => 'pending',
            'pickup_address' => '123 CDO Street',
            'pickup_lat' => 8.4542,
            'pickup_lng' => 124.6319,
            'dropoff_address' => '456 Limketkai Ave',
            'dropoff_lat' => 8.4600,
            'dropoff_lng' => 124.6400,
            'estimated_distance_m' => 3000,
            'estimated_fare' => 55.00,
            'payment_method' => 'cash',
            'payment_status' => 'pending',
        ]);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DRIVER REGISTRATION
    // ═══════════════════════════════════════════════════════════════════════════

    public function test_driver_can_register(): void
    {
        config([
            'filesystems.media_disk' => 's3',
            'filesystems.disks.s3.key' => 'test-key',
            'filesystems.disks.s3.secret' => 'test-secret',
            'filesystems.disks.s3.bucket' => 'test-bucket',
        ]);
        Storage::fake('s3');

        $email = 'testrider_'.time().'@test.com';
        $phone = '+6391712345'.rand(10, 99);

        $response = $this->post('/api/v1/drivers/register', [
            'name' => 'Test Rider',
            'email' => $email,
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
            'phone_number' => $phone,
            'terms_accepted' => true,
            'phone_verification_token' => \App\Services\RegistrationPhoneProof::issue($phone),
            'license_number' => 'N01-23-'.rand(100000, 999999),
            'selfie' => UploadedFile::fake()->image('selfie.jpg'),
            'selfie_with_motorcycle' => UploadedFile::fake()->image('selfie-with-motorcycle.jpg'),
            'resume' => UploadedFile::fake()->create('resume.pdf', 100, 'application/pdf'),
            'barangay_clearance' => UploadedFile::fake()->create('barangay-clearance.pdf', 100, 'application/pdf'),
            'drivers_license' => UploadedFile::fake()->image('drivers-license.jpg'),
            'motorcycle_orcr' => UploadedFile::fake()->create('motorcycle-orcr.pdf', 100, 'application/pdf'),
            'scanned_orcr' => UploadedFile::fake()->create('scanned-orcr.pdf', 100, 'application/pdf'),
            'digital_signature' => UploadedFile::fake()->create('digital-signature.pdf', 100, 'application/pdf'),
        ], ['Accept' => 'application/json']);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.driver_profile.status', 'pending')
            ->assertJsonPath('data.user.registration_fee.is_active', false)
            ->assertJsonStructure([
                'token',
                'data' => ['user', 'driver_profile'],
            ]);

        $this->assertDatabaseHas('users', [
            'email' => $email,
            'phone_number' => $phone,
        ]);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DRIVER LOGIN & AUTH
    // ═══════════════════════════════════════════════════════════════════════════

    public function test_driver_can_login(): void
    {
        $user = User::factory()->create([
            'role' => 'driver',
            'email' => 'rider@test.com',
            'password' => bcrypt('password123'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'rider@test.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['token', 'user']);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LOAD ORDERS (RIDER SEES AVAILABLE ORDERS)
    // ═══════════════════════════════════════════════════════════════════════════

    public function test_driver_sees_available_orders(): void
    {
        $this->actingAs($this->driver, 'sanctum');

        $response = $this->getJson('/api/v1/orders');

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        // Driver should see the pending unassigned order
        $orders = collect($response->json('data.data') ?? $response->json('data'));
        $found = $orders->firstWhere('id', $this->order->id);
        $this->assertNotNull($found, 'Driver should see pending unassigned order');
        $this->assertEquals('pending', $found['status']);
    }

    public function test_driver_does_not_see_other_drivers_orders(): void
    {
        // Assign order to another driver
        $otherDriver = DriverProfile::factory()->create(['status' => 'active']);
        $assignedOrder = Order::factory()->create([
            'customer_id' => User::factory()->create(['role' => 'customer'])->id,
            'service_id' => $this->service->id,
            'driver_id' => $otherDriver->id,
            'status' => 'accepted',
        ]);

        $this->actingAs($this->driver, 'sanctum');

        $response = $this->getJson('/api/v1/orders');
        $orders = collect($response->json('data.data') ?? $response->json('data'));
        $found = $orders->firstWhere('id', $assignedOrder->id);
        $this->assertNull($found, 'Driver should not see orders assigned to others');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ACCEPT ORDER
    // ═══════════════════════════════════════════════════════════════════════════

    public function test_driver_can_accept_order(): void
    {
        $this->actingAs($this->driver, 'sanctum');

        // Give driver sufficient wallet balance
        $this->driver->wallet()->create(['balance' => 100]);

        $response = $this->patchJson("/api/v1/orders/{$this->order->id}/status", [
            'status' => 'accepted',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'accepted')
            ->assertJsonPath('data.driver_id', $this->driverProfile->id);
    }

    public function test_driver_cannot_accept_already_accepted_order(): void
    {
        $this->actingAs($this->driver, 'sanctum');
        $this->driver->wallet()->create(['balance' => 100]);

        // Another driver already accepted
        $otherProfile = DriverProfile::factory()->create(['status' => 'active']);
        $this->order->update(['driver_id' => $otherProfile->id, 'status' => 'accepted']);

        $response = $this->patchJson("/api/v1/orders/{$this->order->id}/status", [
            'status' => 'accepted',
        ]);

        // Ownership authorization runs before transition/conflict validation.
        $response->assertForbidden();
        $this->assertSame($otherProfile->id, $this->order->fresh()->driver_id);
    }

    public function test_inactive_driver_cannot_accept(): void
    {
        $this->driverProfile->update(['status' => 'pending']);
        $this->actingAs($this->driver, 'sanctum');
        $this->driver->wallet()->create(['balance' => 100]);

        $response = $this->patchJson("/api/v1/orders/{$this->order->id}/status", [
            'status' => 'accepted',
        ]);

        $response->assertStatus(403);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // STATUS TRANSITIONS
    // ═══════════════════════════════════════════════════════════════════════════

    public function test_full_status_flow_accepted_to_completed(): void
    {
        $this->actingAs($this->driver, 'sanctum');
        $this->driver->wallet()->create(['balance' => 100]);

        // Accept
        $this->patchJson("/api/v1/orders/{$this->order->id}/status", ['status' => 'accepted'])
            ->assertStatus(200);

        // Driver arrived
        $this->patchJson("/api/v1/orders/{$this->order->id}/status", ['status' => 'driver_arrived_at_pickup'])
            ->assertStatus(200)
            ->assertJsonPath('data.status', 'driver_arrived_at_pickup');

        // In progress
        $this->patchJson("/api/v1/orders/{$this->order->id}/status", ['status' => 'in_progress'])
            ->assertStatus(200)
            ->assertJsonPath('data.status', 'in_progress');

        // Picked up
        $this->patchJson("/api/v1/orders/{$this->order->id}/status", ['status' => 'picked_up'])
            ->assertStatus(200)
            ->assertJsonPath('data.status', 'picked_up');

        // Completed
        // The upload endpoint persists proof before completion (covered separately).
        $this->order->refresh()->update(['proof_images' => ['proof_images/delivery.jpg']]);
        $this->patchJson("/api/v1/orders/{$this->order->id}/status", ['status' => 'completed'])
            ->assertStatus(200)
            ->assertJsonPath('data.status', 'completed');

        // Verify payment marked as paid for cash orders
        $this->order->refresh();
        $this->assertEquals('paid', $this->order->payment_status);
    }

    public function test_cannot_skip_to_completed_from_accepted(): void
    {
        $this->actingAs($this->driver, 'sanctum');
        $this->driver->wallet()->create(['balance' => 100]);

        $this->patchJson("/api/v1/orders/{$this->order->id}/status", ['status' => 'accepted'])
            ->assertStatus(200);

        // Try to skip directly to completed (should fail)
        $this->patchJson("/api/v1/orders/{$this->order->id}/status", ['status' => 'completed'])
            ->assertStatus(403);
    }

    public function test_cannot_update_status_after_completed(): void
    {
        $this->actingAs($this->driver, 'sanctum');
        $this->driver->wallet()->create(['balance' => 100]);

        // Fast-track to completed
        $this->order->update([
            'driver_id' => $this->driverProfile->id,
            'status' => 'completed',
        ]);

        $this->patchJson("/api/v1/orders/{$this->order->id}/status", ['status' => 'picked_up'])
            ->assertStatus(403);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CANCELLATION
    // ═══════════════════════════════════════════════════════════════════════════

    public function test_customer_can_cancel_before_pickup(): void
    {
        $customer = User::find($this->order->customer_id);
        $this->actingAs($customer, 'sanctum');

        $response = $this->patchJson("/api/v1/orders/{$this->order->id}/status", [
            'status' => 'cancelled',
            'cancel_reason' => 'Changed my mind',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'cancelled');
    }

    public function test_customer_cannot_cancel_after_pickup(): void
    {
        $customer = User::find($this->order->customer_id);
        $this->order->update([
            'driver_id' => $this->driverProfile->id,
            'status' => 'picked_up',
        ]);
        $this->actingAs($customer, 'sanctum');

        $response = $this->patchJson("/api/v1/orders/{$this->order->id}/status", [
            'status' => 'cancelled',
            'cancel_reason' => 'Too late',
        ]);

        $response->assertStatus(403);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DRIVER PROFILE & LOCATION
    // ═══════════════════════════════════════════════════════════════════════════

    public function test_driver_can_update_availability(): void
    {
        $this->actingAs($this->driver, 'sanctum');

        $response = $this->patchJson("/api/v1/drivers/{$this->driverProfile->id}", [
            'is_available' => true,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_driver_can_update_location(): void
    {
        $this->actingAs($this->driver, 'sanctum');

        $response = $this->patchJson("/api/v1/drivers/{$this->driverProfile->id}/location", [
            'last_latitude' => 8.4550,
            'last_longitude' => 124.6325,
        ]);

        $response->assertStatus(200);

        $this->driverProfile->refresh();
        $this->assertEquals(8.4550, $this->driverProfile->last_latitude);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ORDER ESTIMATE
    // ═══════════════════════════════════════════════════════════════════════════

    public function test_fare_estimate_returns_breakdown(): void
    {
        $this->actingAs($this->driver, 'sanctum');

        $response = $this->postJson('/api/v1/orders/estimate', [
            'service_id' => $this->service->id,
            'pickup' => ['lat' => 8.4542, 'lng' => 124.6319],
            'dropoff' => ['lat' => 8.4700, 'lng' => 124.6500],
            'estimated_distance_m' => 5000,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'estimated_fare',
                    'distance_km',
                    'fare_breakdown' => [
                        'base_fare',
                        'distance_fare',
                        'service_fee',
                        'total',
                    ],
                ],
            ]);

        $data = $response->json('data');
        $this->assertGreaterThan(0, $data['estimated_fare']);
        $this->assertGreaterThanOrEqual(40, $data['fare_breakdown']['base_fare']);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PROOF UPLOAD AUTHORIZATION
    // ═══════════════════════════════════════════════════════════════════════════

    public function test_non_assigned_driver_cannot_upload_proof(): void
    {
        $otherDriver = User::factory()->create(['role' => 'driver']);
        DriverProfile::factory()->create(['user_id' => $otherDriver->id, 'status' => 'active']);

        $this->order->update([
            'driver_id' => $this->driverProfile->id,
            'status' => 'picked_up',
        ]);

        $this->payAndApprove($otherDriver);
        $this->actingAs($otherDriver, 'sanctum');

        $response = $this->postJson("/api/v1/orders/{$this->order->id}/upload-proof", [
            'images' => [],
        ]);

        $response->assertStatus(403);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MERCHANT ORDER ACTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    public function test_merchant_can_accept_order(): void
    {
        $merchant = User::factory()->create(['role' => 'partner_admin']);
        $partner = \App\Models\Partner::factory()->create(['user_id' => $merchant->id]);

        $this->order->update(['partner_id' => $partner->id]);

        $this->payAndApprove($merchant);
        $this->actingAs($merchant, 'sanctum');

        $response = $this->patchJson("/api/v1/orders/{$this->order->id}/status", [
            'status' => 'searching_driver',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'searching_driver');
    }

    public function test_merchant_can_mark_ready_for_pickup(): void
    {
        $merchant = User::factory()->create(['role' => 'partner_admin']);
        $partner = \App\Models\Partner::factory()->create(['user_id' => $merchant->id]);

        $this->order->update([
            'partner_id' => $partner->id,
            'status' => 'searching_driver',
        ]);

        $this->payAndApprove($merchant);
        $this->actingAs($merchant, 'sanctum');

        $response = $this->patchJson("/api/v1/orders/{$this->order->id}/status", [
            'status' => 'ready_for_pickup',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'ready_for_pickup');
    }

    public function test_merchant_cannot_cancel_after_pickup(): void
    {
        $merchant = User::factory()->create(['role' => 'partner_admin']);
        $partner = \App\Models\Partner::factory()->create(['user_id' => $merchant->id]);

        $this->order->update([
            'partner_id' => $partner->id,
            'driver_id' => $this->driverProfile->id,
            'status' => 'picked_up',
        ]);

        $this->payAndApprove($merchant);
        $this->actingAs($merchant, 'sanctum');

        $response = $this->patchJson("/api/v1/orders/{$this->order->id}/status", [
            'status' => 'cancelled',
        ]);

        $response->assertStatus(403);
    }
}
