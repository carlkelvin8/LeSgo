<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Jobs\ProcessPaymentWebhookJob;
use App\Models\Order;
use App\Models\Payment;
use App\Models\PaymentRefund;
use App\Models\WalletTopUp;
use App\Services\CacheService;
use App\Services\LesPayTopUpFeeService;
use App\Services\OrderWalletPaymentService;
use App\Services\PaymentGatewayManager;
use App\Services\WalletValidationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

/**
 * Mobile-app payment gateway routes (/v1/payment-gateway/*).
 */
class PaymentGatewayInvoicesController extends Controller
{
    public function __construct(private PaymentGatewayManager $gateway) {}

    public function createInvoice(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount' => 'required|numeric|min:10|max:100000',
            'description' => 'required|string|max:255',
            'payment_method' => 'required|string|in:paymongo,xendit,gcash,maya,paymaya,card',
            'success_url' => 'nullable|string|max:500',
            'cancel_url' => 'nullable|string|max:500',
            'metadata' => 'nullable|array',
            'metadata.type' => 'nullable|string|in:wallet_topup,order_payment',
            'metadata.order_id' => 'required_if:metadata.type,order_payment|integer|exists:orders,id',
            'metadata.provider' => 'nullable|string|in:paymongo,xendit',
        ]);

        $validated['payment_method'] = $this->normalizePaymentMethod(
            $validated['payment_method']
        );

        $meta = $validated['metadata'] ?? [];
        $type = $meta['type'] ?? 'wallet_topup';
        $provider = $meta['provider'] ?? null;

        if ($type === 'order_payment') {
            return $this->createOrderPaymentInvoice($request, $validated, $meta, $provider);
        }

        return $this->createWalletTopUpInvoice($request, $validated, $meta, $provider);
    }

    public function getInvoice(Request $request, string $invoiceId): JsonResponse
    {
        try {
            $topUp = WalletTopUp::where('user_id', $request->user()->id)
                ->where(function ($query) use ($invoiceId) {
                    $query->where('gateway_reference', $invoiceId)
                        ->orWhere('xendit_invoice_id', $invoiceId);
                })
                ->first();

            $payment = null;
            if (! $topUp) {
                $payment = Payment::where('provider_reference', $invoiceId)
                    ->where('customer_id', $request->user()->id)
                    ->first();
            }

            if (! $topUp && ! $payment) {
                return $this->error('Invoice record not found.', 404);
            }

            $provider = strtolower((string) ($topUp?->provider ?? $payment?->provider ?? 'xendit'));
            $paymentMethod = (string) ($topUp?->payment_method ?? $payment?->method ?? $provider);
            $invoice = $this->gateway->getInvoice($invoiceId, $provider);
            $normalizedStatus = $this->gateway->normalizeInvoiceStatus($invoice, $provider);

            if ($normalizedStatus !== 'pending') {
                (new ProcessPaymentWebhookJob($provider, [
                    'id' => $invoiceId,
                    'status' => strtoupper($normalizedStatus),
                ]))->handle();
                $invoice['status'] = strtoupper($normalizedStatus);
            }

            $payload = $this->formatInvoicePayload($invoice, $paymentMethod, $provider);
            if (! empty($payment?->order_id)) {
                $payload['order_id'] = (int) $payment->order_id;
            }

            return $this->success($payload);
        } catch (\Throwable $e) {
            return $this->error($e->getMessage(), 502);
        }
    }

    public function validateWallet(Request $request): JsonResponse
    {
        $user = $request->user();
        $wallet = WalletValidationService::ensureWalletExists($user);
        $balance = (float) $wallet->balance;
        $threshold = WalletValidationService::getMinimumThreshold();
        $isValid = $balance >= $threshold;

        return response()->json([
            'success' => true,
            'is_valid' => $isValid,
            'current_balance' => $balance,
            'minimum_threshold' => $threshold,
            'needs_topup' => ! $isValid,
            'message' => $isValid
                ? 'Wallet balance is sufficient.'
                : 'Top up your LesPay wallet to continue.',
        ]);
    }

    public function walletThreshold(): JsonResponse
    {
        $threshold = WalletValidationService::getMinimumThreshold();

        return response()->json([
            'success' => true,
            'minimum_threshold' => $threshold,
            'recommended_topup' => max($threshold, 500),
        ]);
    }

    /**
     * Mobile refund request (maps payment_id to gateway reference).
     */
    public function requestRefund(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'payment_id' => 'required_without:payment_request_id|integer|exists:payments,id',
            'payment_request_id' => 'required_without:payment_id|string|max:255',
            'amount' => 'required|numeric|min:1',
            'reason' => 'nullable|string|max:255',
        ]);

        $user = $request->user();
        $payment = ! empty($validated['payment_id'])
            ? Payment::find($validated['payment_id'])
            : Payment::where('provider_reference', $validated['payment_request_id'])->first();

        if (! $payment) {
            return $this->error('Payment record not found.', 404);
        }

        if ((int) $payment->customer_id !== (int) $user->id && ! $user->isAdmin()) {
            return $this->error('You can only refund your own payments.', 403);
        }

        if (! $user->isAdmin() && $payment->order?->status !== 'cancelled') {
            return $this->error(
                'Customer refunds can only be issued after the order is cancelled.',
                422,
            );
        }

        if ($payment->status !== 'paid') {
            return $this->error('Only completed payments can be refunded.', 422);
        }

        if ((int) round((float) $validated['amount'] * 100) > (int) round((float) $payment->amount * 100)) {
            return $this->error('Refund amount cannot exceed the original payment.', 422);
        }

        if (! $user->isAdmin()
            && (int) round((float) $validated['amount'] * 100) !== (int) round((float) $payment->amount * 100)) {
            return $this->error('Customer refunds must cover the full payment amount.', 422);
        }

        $paymentRequestId = $payment->provider_reference
            ?? data_get($payment->meta, 'payment_request_id');
        $provider = strtolower((string) $payment->provider);

        if (! $paymentRequestId) {
            return $this->error('Payment gateway reference not found for this payment.', 422);
        }

        if (! in_array($provider, ['paymongo', 'xendit'], true)) {
            return $this->error('Payment gateway provider is missing or unsupported.', 422);
        }

        try {
            $provider = $this->gateway->resolveProvider($provider);
        } catch (\Throwable $error) {
            return $this->error($error->getMessage(), 503);
        }

        $reason = strtoupper($validated['reason'] ?? 'REQUESTED_BY_CUSTOMER');
        if (! in_array($reason, ['DUPLICATE', 'FRAUDULENT', 'REQUESTED_BY_CUSTOMER'], true)) {
            $reason = 'REQUESTED_BY_CUSTOMER';
        }

        $refundRecord = DB::transaction(function () use ($payment, $user, $validated, $provider, $paymentRequestId, $reason) {
            $lockedPayment = Payment::query()
                ->whereKey($payment->id)
                ->lockForUpdate()
                ->firstOrFail();
            $reservedAmount = (float) PaymentRefund::query()
                ->where('payment_id', $lockedPayment->id)
                ->whereIn('status', PaymentRefund::RESERVED_STATUSES)
                ->sum('amount');
            $requestedAmount = round((float) $validated['amount'], 2);

            if ($reservedAmount + $requestedAmount > (float) $lockedPayment->amount + 0.01) {
                throw ValidationException::withMessages([
                    'amount' => ['This payment already has a refund in progress or completed.'],
                ]);
            }

            return PaymentRefund::create([
                'payment_id' => $lockedPayment->id,
                'requested_by' => $user->id,
                'amount' => $requestedAmount,
                'currency' => $lockedPayment->currency,
                'provider' => $provider,
                'payment_reference' => $paymentRequestId,
                'idempotency_key' => (string) Str::uuid(),
                'status' => 'processing',
                'reason' => $reason,
            ]);
        });

        try {
            $refund = $this->gateway->createRefund(
                $paymentRequestId,
                (float) $validated['amount'],
                $reason,
                $provider,
                $refundRecord->idempotency_key,
            );

            $gatewayStatus = strtoupper((string) ($refund['status'] ?? ''));
            $refundStatus = match ($gatewayStatus) {
                'SUCCEEDED', 'COMPLETED', 'REFUNDED' => 'completed',
                'FAILED', 'REJECTED', 'CANCELLED' => 'failed',
                default => 'submitted',
            };
            $refundRecord->update([
                'gateway_reference' => $refund['id'] ?? null,
                'status' => $refundStatus,
                'completed_at' => $refundStatus === 'completed' ? now() : null,
                'failure_reason' => $refundStatus === 'failed'
                    ? (string) ($refund['message'] ?? 'Gateway rejected the refund.')
                    : null,
                'meta' => ['gateway_status' => $refund['status'] ?? null],
            ]);

            if ($refundStatus === 'completed') {
                $this->markPaymentRefundedWhenFullyRefunded($payment);
            }

            $refund['refund_record_id'] = $refundRecord->id;

            return $this->success($refund, 'Refund request submitted successfully');
        } catch (\Throwable $e) {
            $refundRecord->update([
                'status' => 'verification_required',
                'failure_reason' => $e->getMessage(),
            ]);

            return $this->error($e->getMessage(), 502);
        }
    }

    private function markPaymentRefundedWhenFullyRefunded(Payment $payment): void
    {
        DB::transaction(function () use ($payment) {
            $lockedPayment = Payment::query()
                ->whereKey($payment->id)
                ->lockForUpdate()
                ->firstOrFail();
            $completedAmount = (float) PaymentRefund::query()
                ->where('payment_id', $lockedPayment->id)
                ->where('status', 'completed')
                ->sum('amount');

            if ($completedAmount + 0.01 < (float) $lockedPayment->amount) {
                return;
            }

            $lockedPayment->update(['status' => 'refunded']);
            $lockedPayment->order()->update(['payment_status' => 'refunded']);
        });
    }

    private function createWalletTopUpInvoice(
        Request $request,
        array $validated,
        array $meta,
        ?string $provider,
    ): JsonResponse {
        $user = $request->user();
        $wallet = WalletValidationService::ensureWalletExists($user);
        $externalId = 'lespay-topup-'.$user->id.'-'.Str::uuid();
        $walletAmount = (float) $validated['amount'];
        $pricing = LesPayTopUpFeeService::calculate($walletAmount);

        $invoiceMeta = [
            'success_redirect_url' => $validated['success_url'] ?? 'lesgo://lespay/topup/success',
            'failure_redirect_url' => $validated['cancel_url'] ?? 'lesgo://lespay/topup/failure',
            'customer_email' => $user->email,
            'customer_name' => $user->name,
            'payer_email' => $user->email,
            'payer_name' => $user->name,
            'payer_phone' => $user->phone_number,
            'payment_methods' => $this->xenditPaymentMethods($validated['payment_method']),
            'payment_method' => $validated['payment_method'],
        ];

        try {
            $invoice = $this->gateway->createInvoice(
                $pricing['total_charged'],
                $externalId,
                $validated['description'],
                $invoiceMeta,
                $provider,
            );

            $resolvedProvider = $invoice['provider'] ?? $this->gateway->resolveProvider($provider);

            try {
                WalletTopUp::create([
                    'user_id' => $user->id,
                    'wallet_id' => $wallet->id,
                    'amount' => $pricing['wallet_amount'],
                    'fee' => $pricing['fee'],
                    'total_charged' => $pricing['total_charged'],
                    'currency' => 'PHP',
                    'status' => 'pending',
                    'payment_method' => $validated['payment_method'],
                    'provider' => $resolvedProvider,
                    'xendit_invoice_id' => $resolvedProvider === 'xendit' ? $invoice['id'] : null,
                    'gateway_reference' => $invoice['id'],
                    'external_id' => $externalId,
                    'invoice_url' => $invoice['invoice_url'],
                    'meta' => array_merge($meta, [
                        'fee_rate' => $pricing['fee_rate'],
                        'wallet_amount' => $pricing['wallet_amount'],
                        'fee' => $pricing['fee'],
                    ]),
                ]);
            } catch (\Throwable $dbErr) {
                Log::warning('WalletTopUp persist failed after gateway invoice created', [
                    'external_id' => $externalId,
                    'invoice_id' => $invoice['id'],
                    'provider' => $resolvedProvider,
                    'error' => $dbErr->getMessage(),
                ]);

                throw new \RuntimeException(
                    'The payment invoice could not be recorded. Please do not pay it and try again.',
                    previous: $dbErr,
                );
            }

            $payload = $this->formatInvoicePayload($invoice, $validated['payment_method'], $resolvedProvider);
            $payload['fee'] = $pricing['fee'];
            $payload['wallet_amount'] = $pricing['wallet_amount'];
            $payload['total_charged'] = $pricing['total_charged'];

            return $this->created(
                $payload,
                'Invoice created — open invoice_url to complete payment'
            );
        } catch (\Throwable $e) {
            return $this->error($e->getMessage(), 502);
        }
    }

    private function createOrderPaymentInvoice(
        Request $request,
        array $validated,
        array $meta,
        ?string $provider,
    ): JsonResponse {
        $user = $request->user();
        $order = Order::findOrFail((int) $meta['order_id']);

        if (! $user->isAdmin() && (int) $order->customer_id !== (int) $user->id) {
            return $this->error('You can only pay for your own orders.', 403);
        }

        if ($order->payment_status === 'paid') {
            return $this->error('Order is already paid.', 409);
        }

        $amount = OrderWalletPaymentService::resolvePayableAmount($order);
        if ($amount <= 0) {
            return $this->error('This order does not have a valid payable amount.', 422);
        }

        if ((int) round((float) $validated['amount'] * 100) !== (int) round($amount * 100)) {
            return $this->error('The payment amount does not match the order total.', 422);
        }

        $method = $validated['payment_method'];
        $resolvedProvider = $this->gateway->resolveProvider($provider);
        [$paymentAttempt, $isNewAttempt] = DB::transaction(function () use ($order, $amount, $method, $resolvedProvider) {
            Order::query()->whereKey($order->id)->lockForUpdate()->firstOrFail();
            $existingPending = Payment::query()
                ->where('order_id', $order->id)
                ->where('status', 'pending')
                ->latest('id')
                ->lockForUpdate()
                ->first();
            if ($existingPending) {
                return [$existingPending, false];
            }

            // Persist an attempt before contacting the provider. The order
            // lock plus this pending row prevents concurrent taps from
            // creating multiple payable invoices for one order.
            return [Payment::create([
                'order_id' => $order->id,
                'customer_id' => $order->customer_id,
                'partner_id' => $order->partner_id,
                'amount' => $amount,
                'currency' => 'PHP',
                'method' => $method,
                'status' => 'pending',
                'provider' => $resolvedProvider,
                'meta' => ['type' => 'order_payment', 'preparing' => true],
            ]), true];
        });

        if (! $isNewAttempt && $paymentAttempt->provider_reference && data_get($paymentAttempt->meta, 'invoice_url')) {
            $existingUrl = data_get($paymentAttempt->meta, 'invoice_url');
            return $this->success([
                'invoice_id' => $paymentAttempt->provider_reference,
                'invoice_url' => $existingUrl,
                'order_id' => $order->id,
                'amount' => (float) $paymentAttempt->amount,
                'currency' => $paymentAttempt->currency,
                'status' => 'pending',
                'payment_method' => $paymentAttempt->method,
                'provider' => $paymentAttempt->provider,
                'expires_at' => data_get($paymentAttempt->meta, 'expires_at'),
            ], 'An active payment invoice already exists.');
        }
        if (! $isNewAttempt) {
            return $this->error(
                'A payment attempt is already being prepared. Please retry in a moment.',
                409,
            );
        }

        $externalId = 'lesgo-order-'.$order->id.'-payment-'.$paymentAttempt->id;

        $invoiceMeta = [
            'success_redirect_url' => $validated['success_url'] ?? 'lesgo://order/payment/success',
            'failure_redirect_url' => $validated['cancel_url'] ?? 'lesgo://order/payment/failure',
            'customer_email' => $user->email,
            'customer_name' => $user->name,
            'payer_email' => $user->email,
            'payer_name' => $user->name,
            'payer_phone' => $user->phone_number,
            'payment_methods' => $this->xenditPaymentMethods($method),
            'payment_method' => $method,
        ];

        try {
            $invoice = $this->gateway->createInvoice(
                $amount,
                $externalId,
                $validated['description'],
                $invoiceMeta,
                $provider,
            );

            $resolvedProvider = $invoice['provider'] ?? $resolvedProvider;

            try {
                // Keep one immutable payment attempt per gateway invoice. A
                // retry after failure never overwrites an older reference.
                $paymentAttempt->update([
                    'provider' => $resolvedProvider,
                    'provider_reference' => $invoice['id'],
                    'meta' => [
                        'external_id' => $externalId,
                        'invoice_url' => $invoice['invoice_url'],
                        'expires_at' => $invoice['expiry_date'] ?? null,
                        'type' => 'order_payment',
                    ],
                ]);

                $order->update([
                    'payment_method' => $method,
                    'payment_status' => 'pending',
                ]);

                CacheService::forgetByPattern("payments:user:{$order->customer_id}:list:*");
            } catch (\Throwable $dbErr) {
                Log::warning('Order payment persist failed after gateway invoice created', [
                    'order_id' => $order->id,
                    'external_id' => $externalId,
                    'invoice_id' => $invoice['id'],
                    'provider' => $resolvedProvider,
                    'error' => $dbErr->getMessage(),
                ]);

                throw new \RuntimeException(
                    'The payment invoice could not be recorded. Please do not pay it and try again.',
                    previous: $dbErr,
                );
            }

            $payload = $this->formatInvoicePayload($invoice, $method, $resolvedProvider);
            $payload['order_id'] = (int) $order->id;

            return $this->created(
                $payload,
                'Invoice created — open invoice_url to complete payment'
            );
        } catch (\Throwable $e) {
            if ($paymentAttempt->provider_reference === null) {
                $paymentAttempt->update([
                    'status' => 'failed',
                    'meta' => array_merge($paymentAttempt->meta ?? [], [
                        'preparing' => false,
                        'preparation_error' => 'gateway_invoice_creation_failed',
                    ]),
                ]);
            }
            return $this->error($e->getMessage(), 502);
        }
    }

    private function normalizePaymentMethod(string $method): string
    {
        return match (strtolower($method)) {
            'paymaya' => 'maya',
            default => strtolower($method),
        };
    }

    /**
     * @return list<string>|null
     */
    private function xenditPaymentMethods(string $method): ?array
    {
        return match ($method) {
            'gcash' => ['GCASH'],
            'maya' => ['PAYMAYA'],
            'card' => ['CREDIT_CARD', 'DEBIT_CARD'],
            default => null,
        };
    }

    private function formatInvoicePayload(array $invoice, string $paymentMethod, string $provider = 'paymongo'): array
    {
        return [
            'invoice_id' => $invoice['id'],
            'invoice_url' => $invoice['invoice_url'] ?? $invoice['checkout_url'] ?? null,
            'order_id' => null,
            'amount' => (float) ($invoice['amount'] ?? 0),
            'currency' => $invoice['currency'] ?? 'PHP',
            'status' => strtolower($invoice['status'] ?? 'pending'),
            'payment_method' => $paymentMethod,
            'provider' => $provider,
            'paid_at' => $invoice['paid_at'] ?? null,
            'expires_at' => $invoice['expiry_date'] ?? now()->addDay()->toIso8601String(),
        ];
    }
}
