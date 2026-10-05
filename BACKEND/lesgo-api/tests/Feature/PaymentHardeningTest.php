<?php

namespace Tests\Feature;

use App\Jobs\ProcessPaymentWebhookJob;
use App\Jobs\ProcessCancelledGatewayRefundJob;
use App\Models\DriverPackagePurchase;
use App\Models\DriverProfile;
use App\Models\Order;
use App\Models\Payment;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletLinkedAccount;
use App\Models\WalletTopUp;
use App\Models\WalletWithdrawal;
use App\Services\PaymentGatewayManager;
use App\Services\PaymentGatewayService;
use App\Services\OrderCancellationService;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Facades\DB;
use Mockery;
use Tests\TestCase;

class PaymentHardeningTest extends TestCase
{
    public function test_topup_confirmation_fails_closed_when_gateway_cannot_be_verified(): void
    {
        config(['services.xendit.secret_key' => '']);
        $user = User::factory()->create();
        $wallet = Wallet::factory()->create(['user_id' => $user->id, 'balance' => 0]);
        $topUp = $this->createTopUp($user, $wallet, 'inv-unavailable');

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/wallets/my/topup', [
                'gateway_reference' => 'inv-unavailable',
            ])->assertStatus(502);

        $this->assertSame('pending', $topUp->fresh()->status);
        $this->assertSame(0.0, (float) $wallet->fresh()->balance);
    }

    public function test_mobile_invoice_lookup_cannot_access_another_users_topup(): void
    {
        $victim = User::factory()->create();
        $victimWallet = Wallet::factory()->create(['user_id' => $victim->id]);
        $this->createTopUp($victim, $victimWallet, 'victim-reference');
        $attacker = User::factory()->create();

        $this->actingAs($attacker, 'sanctum')
            ->getJson('/api/v1/payment-gateway/invoices/victim-reference')
            ->assertNotFound();
    }

    public function test_order_invoice_rejects_a_client_supplied_underpayment(): void
    {
        $customer = User::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'estimated_fare' => 500,
            'discount_amount' => 0,
            'payment_status' => 'pending',
        ]);

        $this->actingAs($customer, 'sanctum')
            ->postJson('/api/v1/payment-gateway/invoices', [
                'amount' => 10,
                'description' => 'Order payment',
                'payment_method' => 'paymongo',
                'metadata' => [
                    'type' => 'order_payment',
                    'order_id' => $order->id,
                ],
            ])->assertUnprocessable()
            ->assertJsonPath('message', 'The payment amount does not match the order total.');

        $this->assertDatabaseMissing('payments', ['order_id' => $order->id]);
    }

    public function test_order_payment_retry_reuses_live_invoice_without_overwriting_reference(): void
    {
        config(['services.paymongo.secret_key' => 'test-secret']);
        $gateway = Mockery::mock(PaymentGatewayManager::class)->makePartial();
        $gateway->shouldReceive('createInvoice')
            ->once()
            ->andReturn([
                'id' => 'invoice-first-attempt',
                'invoice_url' => 'https://checkout.example/first',
                'status' => 'pending',
                'amount' => 500,
                'currency' => 'PHP',
                'provider' => 'paymongo',
            ]);
        $this->app->instance(PaymentGatewayManager::class, $gateway);

        $customer = User::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'estimated_fare' => 500,
            'discount_amount' => 0,
            'payment_status' => 'pending',
        ]);
        $payload = [
            'amount' => 500,
            'description' => 'Order payment',
            'payment_method' => 'gcash',
            'metadata' => [
                'type' => 'order_payment',
                'order_id' => $order->id,
            ],
        ];

        $first = $this->actingAs($customer, 'sanctum')
            ->postJson('/api/v1/payment-gateway/invoices', $payload)
            ->assertCreated();
        $first->assertJsonPath('data.invoice_id', 'invoice-first-attempt');

        $this->postJson('/api/v1/payment-gateway/invoices', $payload)
            ->assertOk()
            ->assertJsonPath('data.invoice_id', 'invoice-first-attempt');

        $this->assertSame(1, Payment::where('order_id', $order->id)->count());
        $this->assertSame(
            'invoice-first-attempt',
            Payment::where('order_id', $order->id)->value('provider_reference'),
        );
    }

    public function test_cancelling_gateway_paid_order_reserves_and_dispatches_full_refund(): void
    {
        Bus::fake();
        $customer = User::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'estimated_fare' => 500,
            'discount_amount' => 0,
            'payment_method' => 'gcash',
            'payment_status' => 'paid',
            'status' => 'accepted',
        ]);
        $payment = Payment::create([
            'order_id' => $order->id,
            'customer_id' => $customer->id,
            'amount' => 500,
            'currency' => 'PHP',
            'method' => 'gcash',
            'status' => 'paid',
            'provider' => 'paymongo',
            'provider_reference' => 'gateway-invoice-cancel-refund',
        ]);

        OrderCancellationService::process($order);

        $this->assertDatabaseHas('payment_refunds', [
            'payment_id' => $payment->id,
            'amount' => 500,
            'status' => 'processing',
            'payment_reference' => 'gateway-invoice-cancel-refund',
        ]);
        Bus::assertDispatched(ProcessCancelledGatewayRefundJob::class);
        $this->assertSame('paid', $payment->fresh()->status);
    }

    public function test_cancelled_order_refund_job_updates_payment_only_after_provider_confirms(): void
    {
        $customer = User::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'estimated_fare' => 500,
            'payment_status' => 'paid',
            'payment_method' => 'gcash',
            'status' => 'cancelled',
        ]);
        $payment = Payment::create([
            'order_id' => $order->id,
            'customer_id' => $customer->id,
            'amount' => 500,
            'currency' => 'PHP',
            'method' => 'gcash',
            'status' => 'paid',
            'provider' => 'paymongo',
            'provider_reference' => 'gateway-invoice-confirmed-refund',
        ]);
        $refund = \App\Models\PaymentRefund::create([
            'payment_id' => $payment->id,
            'requested_by' => $customer->id,
            'amount' => 500,
            'currency' => 'PHP',
            'provider' => 'paymongo',
            'payment_reference' => $payment->provider_reference,
            'idempotency_key' => 'cancel-job-test-'.$payment->id,
            'status' => 'processing',
            'reason' => 'REQUESTED_BY_CUSTOMER',
        ]);
        $gateway = Mockery::mock(PaymentGatewayManager::class);
        $gateway->shouldReceive('createRefund')
            ->once()
            ->with($payment->provider_reference, 500.0, 'REQUESTED_BY_CUSTOMER', 'paymongo', $refund->idempotency_key)
            ->andReturn(['id' => 'refund-confirmed', 'status' => 'SUCCEEDED']);

        (new ProcessCancelledGatewayRefundJob($refund->id))->handle($gateway);

        $this->assertSame('completed', $refund->fresh()->status);
        $this->assertSame('refunded', $payment->fresh()->status);
        $this->assertSame('refunded', $order->fresh()->payment_status);
    }

    public function test_wallet_topup_ignores_untrusted_wallet_amount_metadata(): void
    {
        $gateway = Mockery::mock(PaymentGatewayManager::class);
        $gateway->shouldReceive('createInvoice')
            ->once()
            ->withArgs(fn ($amount) => abs($amount - 101.5) < 0.001)
            ->andReturn([
                'id' => 'checkout-safe-amount',
                'invoice_url' => 'https://checkout.example/safe',
                'status' => 'pending',
                'amount' => 101.5,
                'currency' => 'PHP',
                'provider' => 'paymongo',
            ]);
        $this->app->instance(PaymentGatewayManager::class, $gateway);

        $user = User::factory()->create();
        Wallet::factory()->create(['user_id' => $user->id, 'balance' => 0]);

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/payment-gateway/invoices', [
                'amount' => 100,
                'description' => 'Wallet top-up',
                'payment_method' => 'paymongo',
                'metadata' => [
                    'type' => 'wallet_topup',
                    'wallet_amount' => 50000,
                ],
            ])->assertCreated();

        $topUp = WalletTopUp::where('gateway_reference', 'checkout-safe-amount')->firstOrFail();
        $this->assertSame(100.0, (float) $topUp->amount);
        $this->assertSame(101.5, (float) $topUp->total_charged);
    }

    public function test_driver_package_is_not_upgraded_when_verification_fails(): void
    {
        $driver = User::factory()->driver()->create();
        $profile = DriverProfile::factory()->create([
            'user_id' => $driver->id,
            'package_tier' => 'basic',
        ]);
        $purchase = DriverPackagePurchase::create([
            'user_id' => $driver->id,
            'driver_profile_id' => $profile->id,
            'target_tier' => 'advance',
            'amount' => 999,
            'currency' => 'PHP',
            'status' => 'pending',
            'payment_method' => 'xendit',
            'xendit_invoice_id' => 'inv-package',
            'external_id' => 'package-verification-test',
        ]);

        $xendit = Mockery::mock(PaymentGatewayService::class);
        $xendit->shouldReceive('getInvoice')
            ->once()
            ->with('inv-package')
            ->andThrow(new \RuntimeException('Gateway unavailable.'));
        $this->app->instance(PaymentGatewayService::class, $xendit);

        $this->activatePartner($driver);

        $this->actingAs($driver, 'sanctum')
            ->postJson('/api/v1/drivers/me/package-upgrade', [
                'xendit_invoice_id' => 'inv-package',
            ])->assertUnprocessable();

        $this->assertSame('basic', $profile->fresh()->package_tier);
        $this->assertSame('pending', $purchase->fresh()->status);
    }

    public function test_unknown_gateway_reference_cannot_be_refunded(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/payment-gateway/refunds', [
                'payment_request_id' => 'someone-elses-reference',
                'amount' => 100,
            ])->assertNotFound();
    }

    public function test_refund_reservation_prevents_duplicate_gateway_refunds(): void
    {
        $user = User::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $user->id,
            'status' => 'cancelled',
            'payment_status' => 'paid',
        ]);
        $payment = Payment::factory()->paid()->create([
            'order_id' => $order->id,
            'customer_id' => $user->id,
            'amount' => 500,
            'provider' => 'paymongo',
            'provider_reference' => 'payment-for-refund',
        ]);
        $gateway = Mockery::mock(PaymentGatewayManager::class);
        $gateway->shouldReceive('resolveProvider')
            ->twice()
            ->with('paymongo')
            ->andReturn('paymongo');
        $gateway->shouldReceive('createRefund')
            ->once()
            ->andReturn([
                'id' => 'refund-1',
                'status' => 'pending',
                'amount' => 500,
            ]);
        $this->app->instance(PaymentGatewayManager::class, $gateway);
        $payload = [
            'payment_id' => $payment->id,
            'amount' => 500,
            'reason' => 'REQUESTED_BY_CUSTOMER',
        ];

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/payment-gateway/refunds', $payload)
            ->assertOk();
        $this->postJson('/api/v1/payment-gateway/refunds', $payload)
            ->assertUnprocessable();

        $this->assertDatabaseCount('payment_refunds', 1);
        $this->assertDatabaseHas('payment_refunds', [
            'payment_id' => $payment->id,
            'status' => 'submitted',
            'gateway_reference' => 'refund-1',
        ]);
    }

    public function test_linked_payout_account_details_are_encrypted_at_rest(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/wallets/my/linked-accounts', [
                'provider' => 'gcash',
                'account_number' => '09171234567',
                'account_holder_name' => 'Private Rider',
            ])->assertCreated();

        $response->assertJsonMissing(['account_details_encrypted']);
        $account = WalletLinkedAccount::where('user_id', $user->id)->firstOrFail();
        $raw = (string) DB::table('wallet_linked_accounts')
            ->where('id', $account->id)
            ->value('account_details_encrypted');

        $this->assertStringNotContainsString('09171234567', $raw);
        $this->assertSame('09171234567', $account->account_details_encrypted['account_number']);
        $this->assertArrayNotHasKey('account_number', $account->meta ?? []);
        $this->assertFalse($account->is_verified);

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/wallets/my/linked-accounts/gcash/verify')
            ->assertStatus(409);
        $this->assertFalse($account->fresh()->is_verified);
    }

    public function test_ambiguous_payout_failure_keeps_funds_reserved_for_reconciliation(): void
    {
        config(['services.paymongo.secret_key' => 'sk_test_example']);
        $user = User::factory()->create();
        $wallet = Wallet::factory()->create(['user_id' => $user->id, 'balance' => 1000]);
        WalletLinkedAccount::create([
            'user_id' => $user->id,
            'provider' => 'gcash',
            'account_last4' => '4567',
            'is_verified' => true,
            'account_details_encrypted' => [
                'account_number' => '09171234567',
                'account_holder_name' => 'Test Rider',
            ],
        ]);

        $gateway = Mockery::mock(PaymentGatewayManager::class);
        $gateway->shouldReceive('resolvePayoutProvider')->once()->andReturn('paymongo');
        $gateway->shouldReceive('createPayout')->once()->andThrow(
            new \RuntimeException('Network timeout after request submission.')
        );
        $this->app->instance(PaymentGatewayManager::class, $gateway);

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/wallets/my/withdraw', [
                'amount' => 100,
                'withdrawal_method' => 'gcash',
            ])->assertUnprocessable();

        $this->assertSame(900.0, (float) $wallet->fresh()->balance);
        $this->assertDatabaseHas('wallet_withdrawals', [
            'user_id' => $user->id,
            'amount' => 100,
            'status' => 'verification_required',
        ]);
    }

    public function test_failed_payout_webhook_reverses_wallet_exactly_once(): void
    {
        $user = User::factory()->create();
        $wallet = Wallet::factory()->create(['user_id' => $user->id, 'balance' => 900]);
        $withdrawal = WalletWithdrawal::create([
            'user_id' => $user->id,
            'wallet_id' => $wallet->id,
            'amount' => 100,
            'currency' => 'PHP',
            'status' => 'submitted',
            'provider' => 'paymongo',
            'withdrawal_method' => 'gcash',
            'external_reference' => 'withdrawal-external-1',
            'gateway_reference' => 'transfer-1',
            'account_last4' => '4567',
            'debited_at' => now(),
        ]);
        $payload = [
            'id' => 'transfer-1',
            'status' => 'FAILED',
            'event_type' => 'transfer.failed',
            'failure_reason' => 'Destination rejected the payout.',
        ];

        (new ProcessPaymentWebhookJob('paymongo', $payload))->handle();
        (new ProcessPaymentWebhookJob('paymongo', $payload))->handle();

        $this->assertSame(1000.0, (float) $wallet->fresh()->balance);
        $this->assertSame('reversed', $withdrawal->fresh()->status);
        $this->assertDatabaseCount('wallet_transactions', 1);
    }

    private function createTopUp(User $user, Wallet $wallet, string $reference): WalletTopUp
    {
        return WalletTopUp::create([
            'user_id' => $user->id,
            'wallet_id' => $wallet->id,
            'amount' => 100,
            'fee' => 1.5,
            'total_charged' => 101.5,
            'currency' => 'PHP',
            'status' => 'pending',
            'payment_method' => 'gcash',
            'provider' => 'xendit',
            'gateway_reference' => $reference,
            'xendit_invoice_id' => $reference,
            'external_id' => 'topup-'.$reference,
        ]);
    }
}
