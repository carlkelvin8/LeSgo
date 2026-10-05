<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTopUp;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WebhookSecurityTest extends TestCase
{
    use RefreshDatabase;

    // ── Signature verification ────────────────────────────────────────────────

    public function test_webhook_rejects_request_without_xendit_callback_token(): void
    {
        $response = $this->postJson('/api/v1/webhooks/payments/xendit', [
            'id'     => 'inv_123',
            'status' => 'PAID',
        ]);

        $response->assertStatus(400);
    }

    public function test_webhook_rejects_request_without_paymongo_signature(): void
    {
        $response = $this->postJson('/api/v1/webhooks/payments/paymongo', [
            'data' => [
                'attributes' => [
                    'type' => 'checkout_session.payment.paid',
                    'data' => ['id' => 'cs_123', 'attributes' => ['status' => 'paid']],
                ],
            ],
        ]);

        $response->assertStatus(400);
    }

    public function test_webhook_rejects_unconfigured_provider(): void
    {
        // gcash/maya without webhook_secret config should be rejected
        $response = $this->postJson('/api/v1/webhooks/payments/gcash', [
            'id'     => 'inv_123',
            'status' => 'PAID',
        ]);

        $response->assertStatus(400);
    }

    public function test_webhook_rejects_invalid_provider_name(): void
    {
        $response = $this->postJson('/api/v1/webhooks/payments/stripe', [
            'id'     => 'inv_123',
            'status' => 'PAID',
        ]);

        // Should 404 because of whereIn constraint on route
        $response->assertStatus(404);
    }

    // ── Webhook idempotency ───────────────────────────────────────────────────

    public function test_webhook_does_not_double_credit_wallet(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $wallet = Wallet::factory()->create(['user_id' => $user->id, 'balance' => 0]);

        $topUp = WalletTopUp::create([
            'user_id'           => $user->id,
            'wallet_id'         => $wallet->id,
            'amount'            => 200.00,
            'fee'               => 3.00,
            'total_charged'     => 203.00,
            'currency'          => 'PHP',
            'status'            => 'paid',
            'paid_at'           => now(),
            'payment_method'    => 'gcash',
            'provider'          => 'xendit',
            'gateway_reference' => 'inv_already_paid',
            'external_id'       => 'lespay-already-paid',
        ]);

        // Simulate processing a webhook for an already-paid top-up
        // completeTopUp should be idempotent
        $result = \App\Services\WalletService::completeTopUp($topUp);
        $this->assertTrue($result);

        $wallet->refresh();
        $this->assertEquals(0, (float) $wallet->balance); // Should NOT credit again
    }
}
