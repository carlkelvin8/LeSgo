<?php

namespace Tests\Unit;

use App\Services\PaymentGatewayManager;
use App\Services\PaymentGatewayService;
use App\Services\PayMongoService;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class PaymentProviderSafetyTest extends TestCase
{
    public function test_gateway_resolution_uses_only_configured_providers(): void
    {
        config([
            'lespay.default_gateway' => 'paymongo',
            'services.paymongo.secret_key' => '',
            'services.xendit.secret_key' => 'xendit-test-key',
        ]);

        $manager = new PaymentGatewayManager(new PayMongoService, new PaymentGatewayService);

        $this->assertSame('xendit', $manager->resolveProvider());
        $this->expectException(\RuntimeException::class);
        $manager->resolveProvider('paymongo');
    }

    public function test_gateway_resolution_fails_when_nothing_is_configured(): void
    {
        config([
            'services.paymongo.secret_key' => '',
            'services.xendit.secret_key' => '',
        ]);

        $manager = new PaymentGatewayManager(new PayMongoService, new PaymentGatewayService);

        $this->expectException(\RuntimeException::class);
        $manager->resolveProvider();
    }

    public function test_paymongo_is_not_selected_for_payouts_without_a_source_account(): void
    {
        config([
            'lespay.default_gateway' => 'paymongo',
            'services.paymongo.secret_key' => 'sk_test_example',
            'services.paymongo.wallet_account_number' => '',
            'services.xendit.secret_key' => 'xendit-test-key',
        ]);

        $manager = new PaymentGatewayManager(new PayMongoService, new PaymentGatewayService);

        $this->assertSame('xendit', $manager->resolvePayoutProvider());
    }

    public function test_paymongo_transfer_uses_stable_idempotency_and_parses_data_envelope(): void
    {
        config([
            'services.paymongo.secret_key' => 'sk_test_example',
            'services.paymongo.wallet_account_number' => 'source-123',
            'services.paymongo.wallet_account_name' => 'LeSGo Test',
        ]);
        Http::fake([
            'api.paymongo.com/v2/batch_transfers' => Http::response([
                'data' => [
                    'id' => 'batch-1',
                    'transfers' => [[
                        'id' => 'transfer-1',
                        'status' => 'pending',
                        'created_at' => 123456,
                    ]],
                ],
            ], 201),
        ]);

        $result = (new PayMongoService)->createTransfer(
            250,
            'withdrawal-reference-1',
            'GXCHPHM2XXX',
            'Test Rider',
            '09171234567',
        );

        $this->assertSame('transfer-1', $result['id']);
        $this->assertSame('pending', $result['status']);
        Http::assertSent(function (Request $request) {
            return $request->hasHeader('Idempotency-Key', 'withdrawal-reference-1')
                && $request['transfers'][0]['reference_number'] === 'withdrawal-reference-1'
                && $request['transfers'][0]['destination_account']['bic'] === 'GXCHPHM2XXX';
        });
    }

    public function test_paymongo_checkout_uses_requested_method_and_stable_reference(): void
    {
        config(['services.paymongo.secret_key' => 'sk_test_example']);
        Http::fake([
            'api.paymongo.com/v1/checkout_sessions' => Http::response([
                'data' => [
                    'id' => 'checkout-1',
                    'attributes' => [
                        'status' => 'active',
                        'checkout_url' => 'https://checkout.example/1',
                        'currency' => 'PHP',
                    ],
                ],
            ], 201),
        ]);

        (new PayMongoService)->createCheckoutSession(
            100,
            'order-reference-1',
            'Order payment',
            ['payment_method' => 'gcash'],
        );

        Http::assertSent(function (Request $request) {
            $attributes = $request['data']['attributes'];

            return $request->hasHeader('Idempotency-Key', 'order-reference-1')
                && $attributes['reference_number'] === 'order-reference-1'
                && $attributes['payment_method_types'] === ['gcash'];
        });
    }

    public function test_paymongo_checkout_reads_paid_status_from_payment_attributes(): void
    {
        config(['services.paymongo.secret_key' => 'sk_test_example']);
        Http::fake([
            'api.paymongo.com/v1/checkout_sessions/checkout-paid' => Http::response([
                'data' => [
                    'id' => 'checkout-paid',
                    'attributes' => [
                        'status' => 'active',
                        'currency' => 'PHP',
                        'line_items' => [[
                            'amount' => 10150,
                            'quantity' => 1,
                        ]],
                        'payments' => [[
                            'attributes' => ['status' => 'paid'],
                        ]],
                    ],
                ],
            ]),
        ]);

        $session = (new PayMongoService)->getCheckoutSession('checkout-paid');

        $this->assertSame('paid', $session['payment_status']);
        $this->assertSame(101.5, $session['amount']);
    }

    public function test_paymongo_webhook_rejects_a_valid_but_stale_signature(): void
    {
        config(['services.paymongo.webhook_secret' => 'webhook-test-secret']);
        $payload = '{"data":{"id":"event-1"}}';
        $timestamp = (string) now()->subMinutes(10)->timestamp;
        $signature = hash_hmac(
            'sha256',
            $timestamp.'.'.$payload,
            'webhook-test-secret',
        );

        $verified = (new PayMongoService)->verifyWebhookSignature(
            $payload,
            "t={$timestamp},v1={$signature}",
        );

        $this->assertFalse($verified);
    }
}
