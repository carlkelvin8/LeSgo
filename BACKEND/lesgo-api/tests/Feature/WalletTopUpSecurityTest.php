<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTopUp;
use App\Models\WalletTransaction;
use App\Services\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class WalletTopUpSecurityTest extends TestCase
{
    use RefreshDatabase;

    // ── confirmTopUp scoping ──────────────────────────────────────────────────

    public function test_user_cannot_claim_another_users_topup(): void
    {
        $victim = User::factory()->create(['role' => 'customer']);
        $victimWallet = Wallet::factory()->create(['user_id' => $victim->id, 'balance' => 0]);

        $topUp = WalletTopUp::create([
            'user_id' => $victim->id,
            'wallet_id' => $victimWallet->id,
            'amount' => 1000.00,
            'fee' => 15.00,
            'total_charged' => 1015.00,
            'currency' => 'PHP',
            'status' => 'pending',
            'payment_method' => 'gcash',
            'provider' => 'xendit',
            'gateway_reference' => 'inv_victim_123',
            'external_id' => 'lespay-topup-victim',
        ]);

        // Attacker tries to confirm victim's top-up
        $attacker = $this->actingAsRole('customer');
        Wallet::factory()->create(['user_id' => $attacker->id, 'balance' => 0]);

        $response = $this->postJson('/api/v1/wallets/my/topup', [
            'gateway_reference' => 'inv_victim_123',
        ]);

        // Should NOT credit attacker's wallet
        $attackerWallet = Wallet::where('user_id', $attacker->id)->first();
        $this->assertEquals(0, (float) $attackerWallet->balance);

        // Victim's top-up should remain pending
        $topUp->refresh();
        $this->assertEquals('pending', $topUp->status);
    }

    // ── Idempotency ───────────────────────────────────────────────────────────

    public function test_topup_with_same_idempotency_key_returns_cached_response(): void
    {
        $user = $this->actingAsRole('customer');
        Wallet::factory()->create(['user_id' => $user->id, 'balance' => 0]);

        // Simulate a cached idempotency response
        $idempotencyKey = 'test-key-123';
        $cacheKey = "topup:idempotency:{$user->id}:{$idempotencyKey}";
        $cachedData = [
            'invoice_id' => 'inv_cached_123',
            'invoice_url' => 'https://example.com/pay',
            'amount' => 100.00,
            'fee' => 1.50,
            'total_charged' => 101.50,
            'fee_rate' => 0.015,
            'provider' => 'paymongo',
            'status' => 'pending',
        ];
        Cache::put($cacheKey, $cachedData, now()->addMinutes(10));

        $response = $this->postJson('/api/v1/wallets/my/topup', [
            'amount' => 100,
            'payment_method' => 'gcash',
            'idempotency_key' => $idempotencyKey,
        ]);

        $response->assertStatus(201);
        $this->assertEquals('inv_cached_123', $response->json('data.invoice_id'));
    }

    // ── Rate limiting ─────────────────────────────────────────────────────────

    public function test_topup_rate_limited_after_5_requests(): void
    {
        $user = $this->actingAsRole('customer');
        Wallet::factory()->create(['user_id' => $user->id, 'balance' => 0]);

        // Make 5 requests (all will fail because no gateway configured, but rate limit still applies)
        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/v1/wallets/my/topup', [
                'amount' => 100,
                'payment_method' => 'gcash',
            ]);
        }

        // 6th request should be rate limited
        $response = $this->postJson('/api/v1/wallets/my/topup', [
            'amount' => 100,
            'payment_method' => 'gcash',
        ]);

        $response->assertStatus(429);
    }

    public function test_withdraw_rate_limited_after_3_requests(): void
    {
        $user = $this->actingAsRole('customer');
        Wallet::factory()->create(['user_id' => $user->id, 'balance' => 50000]);

        for ($i = 0; $i < 3; $i++) {
            $this->postJson('/api/v1/wallets/my/withdraw', [
                'amount' => 100,
                'withdrawal_method' => 'gcash',
            ]);
        }

        $response = $this->postJson('/api/v1/wallets/my/withdraw', [
            'amount' => 100,
            'withdrawal_method' => 'gcash',
        ]);

        $response->assertStatus(429);
    }

    // ── WalletService::completeTopUp race condition ───────────────────────────

    public function test_complete_topup_is_idempotent(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $wallet = Wallet::factory()->create(['user_id' => $user->id, 'balance' => 0]);

        $topUp = WalletTopUp::create([
            'user_id' => $user->id,
            'wallet_id' => $wallet->id,
            'amount' => 500.00,
            'fee' => 7.50,
            'total_charged' => 507.50,
            'currency' => 'PHP',
            'status' => 'pending',
            'payment_method' => 'gcash',
            'provider' => 'xendit',
            'gateway_reference' => 'inv_test_idempotent',
            'external_id' => 'lespay-topup-idempotent',
        ]);

        // Complete once
        $result1 = WalletService::completeTopUp($topUp);
        $this->assertTrue($result1);

        $wallet->refresh();
        $this->assertEquals(500.00, (float) $wallet->balance);

        // Complete again — should NOT double credit
        $topUp->refresh();
        $result2 = WalletService::completeTopUp($topUp);
        $this->assertTrue($result2);

        $wallet->refresh();
        $this->assertEquals(500.00, (float) $wallet->balance); // Still 500, not 1000
    }

    // ── Anomaly detection blocking ────────────────────────────────────────────

    public function test_topup_blocked_when_money_laundering_pattern_detected(): void
    {
        $user = $this->actingAsRole('customer');
        $wallet = Wallet::factory()->create(['user_id' => $user->id, 'balance' => 10000]);

        // Simulate recent large withdrawals (money laundering pattern)
        for ($i = 0; $i < 5; $i++) {
            $transaction = WalletTransaction::create([
                'wallet_id' => $wallet->id,
                'type' => 'debit',
                'amount' => 5000,
                'balance_before' => 10000 - ($i * 5000),
                'balance_after' => 10000 - (($i + 1) * 5000),
                'description' => 'Withdrawal to GCASH',
                'created_by' => $user->id,
            ]);

            WalletTransaction::whereKey($transaction->id)->update([
                'created_at' => now()->subMinutes(30),
            ]);
        }

        // Try large top-up after large withdrawals
        $response = $this->postJson('/api/v1/wallets/my/topup', [
            'amount' => 5000,
            'payment_method' => 'gcash',
        ]);

        $response->assertStatus(403)
            ->assertJsonFragment(['success' => false]);
    }

    // ── Validation ────────────────────────────────────────────────────────────

    public function test_topup_rejects_amount_below_minimum(): void
    {
        $user = $this->actingAsRole('customer');
        Wallet::factory()->create(['user_id' => $user->id]);

        $this->postJson('/api/v1/wallets/my/topup', [
            'amount' => 5, // min is 10
            'payment_method' => 'gcash',
        ])->assertStatus(422);
    }

    public function test_topup_rejects_amount_above_maximum(): void
    {
        $user = $this->actingAsRole('customer');
        Wallet::factory()->create(['user_id' => $user->id]);

        $this->postJson('/api/v1/wallets/my/topup', [
            'amount' => 200000, // max is 100000
            'payment_method' => 'gcash',
        ])->assertStatus(422);
    }

    public function test_topup_rejects_invalid_payment_method(): void
    {
        $user = $this->actingAsRole('customer');
        Wallet::factory()->create(['user_id' => $user->id]);

        $this->postJson('/api/v1/wallets/my/topup', [
            'amount' => 100,
            'payment_method' => 'bitcoin',
        ])->assertStatus(422);
    }

    public function test_withdraw_rejects_invalid_method(): void
    {
        $user = $this->actingAsRole('customer');
        Wallet::factory()->create(['user_id' => $user->id, 'balance' => 1000]);

        $this->postJson('/api/v1/wallets/my/withdraw', [
            'amount' => 100,
            'withdrawal_method' => 'bitcoin',
        ])->assertStatus(422);
    }

    public function test_topup_requires_authentication(): void
    {
        $this->postJson('/api/v1/wallets/my/topup', [
            'amount' => 100,
            'payment_method' => 'gcash',
        ])->assertStatus(401);
    }

    public function test_withdraw_requires_authentication(): void
    {
        $this->postJson('/api/v1/wallets/my/withdraw', [
            'amount' => 100,
            'withdrawal_method' => 'gcash',
        ])->assertStatus(401);
    }
}
