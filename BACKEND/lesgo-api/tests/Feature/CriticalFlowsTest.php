<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Service;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Tests\TestCase;

/**
 * Smoke tests for critical user flows.
 * These tests verify that the core happy paths work end-to-end.
 */
class CriticalFlowsTest extends TestCase
{
    use RefreshDatabase;

    // ── Full auth flow ────────────────────────────────────────────────────────

    public function test_full_auth_flow_register_login_refresh_logout(): void
    {
        // Register
        $register = $this->post('/api/v1/auth/register', $this->withCustomerIdentity([
            'name'                  => 'Flow Test User',
            'email'                 => 'flow@test.com',
            'phone_number'          => '+639999999999',
            'password'              => 'TestPass123!',
            'password_confirmation' => 'TestPass123!',
            'role'                  => 'customer',
            'terms_accepted'        => true,
            'privacy_accepted'      => true,
        ]), ['Accept' => 'application/json']);
        $register->assertStatus(201);
        $token = $register->json('token');
        $refreshToken = $register->json('refresh_token');

        // Access protected route
        $this->withToken($token)->getJson('/api/v1/auth/me')
             ->assertStatus(200)
             ->assertJsonPath('user.email', 'flow@test.com');

        // Refresh token
        $refresh = $this->postJson('/api/v1/auth/refresh', [
            'refresh_token' => $refreshToken,
        ]);
        $refresh->assertStatus(200);
        $newToken = $refresh->json('token');

        // New token works
        $this->withToken($newToken)->getJson('/api/v1/auth/me')
             ->assertStatus(200);

        // Logout
        $this->withToken($newToken)->postJson('/api/v1/auth/logout')
             ->assertStatus(200);

        // The active token is revoked; a repeated request in this same test
        // process can reuse Laravel's cached guard, so assert persisted state.
        $this->assertSame(0, User::where('email', 'flow@test.com')->firstOrFail()->tokens()->count());
    }

    // ── Order lifecycle ───────────────────────────────────────────────────────

    public function test_order_lifecycle_create_to_cancel(): void
    {
        Bus::fake(); // Nearby-driver SQL uses PostgreSQL trigonometric functions.
        $customer = $this->actingAsRole('customer');
        $service = Service::factory()->create(['code' => 'LESGO']);

        // Create
        $create = $this->postJson('/api/v1/orders', [
            'service_id'           => $service->id,
            'pickup'               => ['address' => 'Santa Praxedes', 'lat' => 18.5187, 'lng' => 120.999],
            'dropoff'              => ['address' => 'Claveria', 'lat' => 18.6058, 'lng' => 121.0779],
            'estimated_distance_m' => 12000,
            'payment_method'       => 'cash',
        ]);
        $create->assertStatus(201);
        $orderId = $create->json('data.id');

        // View
        $this->getJson("/api/v1/orders/{$orderId}")
             ->assertStatus(200)
             ->assertJsonPath('data.status', 'pending');

        // Cancel
        $this->patchJson("/api/v1/orders/{$orderId}/status", [
            'status'        => 'cancelled',
            'cancel_reason' => 'Test cancellation',
        ])->assertStatus(200)
          ->assertJsonPath('data.status', 'cancelled');
    }

    // ── Wallet access control ─────────────────────────────────────────────────

    public function test_wallet_access_control(): void
    {
        $user1 = $this->actingAsRole('customer');
        Wallet::factory()->create(['user_id' => $user1->id, 'balance' => 1000]);

        // Can view own wallet
        $this->getJson('/api/v1/wallets/my/wallet')
             ->assertStatus(200);

        // Can view own transactions
        $this->getJson('/api/v1/wallets/my/transactions')
             ->assertStatus(200);

        // Cannot view other user's wallet
        $user2 = User::factory()->create(['role' => 'customer']);
        Wallet::factory()->create(['user_id' => $user2->id, 'balance' => 5000]);

        $this->getJson("/api/v1/wallets/{$user2->id}")
             ->assertStatus(403);
    }

    // ── Partner listing ───────────────────────────────────────────────────────

    public function test_partners_are_publicly_accessible(): void
    {
        // Public — no auth needed
        $this->getJson('/api/v1/partners')
             ->assertStatus(200);
    }

    // ── Health check ──────────────────────────────────────────────────────────

    public function test_health_endpoints_respond(): void
    {
        $this->getJson('/api/v1/ping')->assertStatus(200);
        $this->getJson('/api/v1/health/liveness')->assertStatus(200);
    }

    // ── My wallet convenience routes ──────────────────────────────────────────

    public function test_my_wallet_auto_creates_wallet(): void
    {
        $user = $this->actingAsRole('customer');

        // No wallet exists yet — should auto-create
        $response = $this->getJson('/api/v1/wallets/my/wallet');
        $response->assertStatus(200);

        $this->assertDatabaseHas('wallets', ['user_id' => $user->id]);
    }

    // ── Notifications ─────────────────────────────────────────────────────────

    public function test_notifications_require_auth(): void
    {
        $this->getJson('/api/v1/notifications')->assertStatus(401);
    }

    public function test_authenticated_user_can_list_notifications(): void
    {
        $this->actingAsRole('customer');
        $this->getJson('/api/v1/notifications')->assertStatus(200);
    }
}
