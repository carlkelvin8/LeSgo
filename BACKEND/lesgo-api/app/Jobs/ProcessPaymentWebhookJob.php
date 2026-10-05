<?php

namespace App\Jobs;

use App\Models\MissionRewardPayout;
use App\Models\Order;
use App\Models\Payment;
use App\Models\RegistrationFeePayment;
use App\Models\WalletTopUp;
use App\Models\WalletWithdrawal;
use App\Services\WalletWithdrawalService;
use App\Services\MissionRewardPayoutService;
use App\Services\NotificationService;
use App\Services\RegistrationFeeService;
use App\Services\WalletService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProcessPaymentWebhookJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 5;
    public int $backoff = 60;

    public function __construct(
        public string $provider,
        public array  $payload
    ) {}

    public function handle(): void
    {
        $reference = $this->payload['id']
            ?? $this->payload['reference']
            ?? null;

        $status = $this->resolveStatus(
            $this->payload['status'] ?? ''
        );

        if (!$reference || !$status) {
            Log::warning('ProcessPaymentWebhookJob: missing reference or status', $this->payload);
            return;
        }

        DB::transaction(function () use ($reference, $status) {
            // First: check registration fee PayMongo checkout (must be before generic payment lookup)
            if ($this->provider === 'paymongo') {
                $regFee = RegistrationFeePayment::where('paymongo_checkout_id', $reference)
                    ->orWhere('paymongo_reference', $reference)
                    ->first();
                if (!$regFee && !empty($this->payload['external_id'])) {
                    $regFee = RegistrationFeePayment::where('paymongo_reference', $this->payload['external_id'])->first();
                }
                // payment.paid events carry the Payment id (pay_...) with no checkout id.
                // Resolve via payment ids collected from the checkout_session webhook.
                if (!$regFee && str_starts_with(strtolower((string) $reference), 'pay_')) {
                    $regFee = RegistrationFeePayment::where('metadata->paymongo_payment_ids', 'like', '%' . $reference . '%')->first();
                }
                // Belt-and-braces: fetch the payment so its metadata.external_id
                // (="paymongo_reference") can resolve the fee even when only the
                // payment.paid event ever arrives.
                if (!$regFee && str_starts_with(strtolower((string) $reference), 'pay_') && \App\Services\PayMongoService::configured()) {
                    try {
                        $payment = app(\App\Services\PayMongoService::class)->getPayment($reference);
                        $externalId = $payment['metadata']['external_id'] ?? null;
                        if ($externalId) {
                            $regFee = RegistrationFeePayment::where('paymongo_reference', $externalId)
                                ->orWhere('paymongo_checkout_id', $externalId)
                                ->first();
                        }
                    } catch (\Throwable $e) {
                        Log::warning('PayMongo payment fetch failed during webhook', [
                            'payment_id' => $reference,
                            'error' => $e->getMessage(),
                        ]);
                    }
                }
                if ($regFee) {
                    if ($status === 'paid') {
                        $wasPaid = $regFee->isPaid();
                        $resolverRef = in_array($reference, [$regFee->paymongo_checkout_id, $regFee->paymongo_reference], true)
                            ? $reference
                            : ($regFee->paymongo_checkout_id ?? $reference);
                        $updated = RegistrationFeeService::handleWebhookSuccess($resolverRef, $this->payload);
                        // Notify only on first successful transition, not duplicate webhooks; failure to notify must not rollback payment
                        if (!$wasPaid && $updated && $updated->isPaid()) {
                            try {
                                NotificationService::send(
                                    user: $regFee->user_id,
                                    type: 'registration.fee.paid',
                                    title: 'Registration Fee Paid',
                                    body: 'Your ₱' . number_format((float) $regFee->amount, 2) . ' registration fee was confirmed via PayMongo. ' . ($updated->application_status === 'approved' && $updated->is_active ? 'Your account is now active.' : 'Awaiting admin approval.'),
                                    data: [
                                        'registration_fee_id' => $regFee->id,
                                        'account_type' => $regFee->account_type,
                                        'paymongo_reference' => $regFee->paymongo_reference,
                                        'is_active' => $updated->is_active,
                                    ],
                                    channel: 'push'
                                );
                            } catch (\Throwable $e) {
                                Log::warning('Registration fee notification failed (payment remains paid)', ['registration_fee_id' => $regFee->id, 'error' => $e->getMessage()]);
                            }
                        }
                    } elseif ($status === 'failed') {
                        RegistrationFeeService::handleWebhookFailed($reference, 'PayMongo payment failed via webhook', $this->payload);
                    }
                    Log::info('ProcessPaymentWebhookJob: registration fee updated', [
                        'registration_fee_id' => $regFee->id,
                        'status' => $status,
                        'provider' => $this->provider,
                    ]);
                    return;
                }
            }

            // Search by gateway_reference (new) or xendit_invoice_id (legacy)
            $topUp = WalletTopUp::where('gateway_reference', $reference)
                ->orWhere('xendit_invoice_id', $reference)
                ->first();

            if ($topUp) {
                if ($status === 'paid' && !$topUp->isPaid()) {
                    WalletService::completeTopUp($topUp);

                    NotificationService::send(
                        user: $topUp->user_id,
                        type: 'wallet.topup',
                        title: 'LesPay Top-up Successful',
                        body: '₱' . number_format((float) $topUp->amount, 2) . ' has been added to your wallet.',
                        data: [
                            'wallet_top_up_id' => $topUp->id,
                            'amount'           => $topUp->amount,
                        ],
                        channel: 'push'
                    );
                } elseif ($status === 'failed' && !$topUp->isPaid()) {
                    $topUp->update(['status' => 'failed']);
                }

                Log::info('ProcessPaymentWebhookJob: wallet top-up updated', [
                    'top_up_id' => $topUp->id,
                    'status'    => $status,
                    'provider'  => $this->provider,
                ]);

                return;
            }

            // For PayMongo transfers (withdrawals), handle transfer status
            if ($this->provider === 'paymongo' && $this->isTransferEvent()) {
                $this->handleTransferStatus($reference, $status);
                return;
            }

            $payment = Payment::where('provider', $this->provider)
                ->where('provider_reference', $reference)->lockForUpdate()->first();

            if (!$payment) {
                Log::warning('ProcessPaymentWebhookJob: payment not found', [
                    'reference' => $reference,
                    'provider'  => $this->provider,
                ]);
                return;
            }

            if ($status === 'paid') {
                $receivedAmount = $this->payload['amount'] ?? null;
                $receivedCurrency = strtoupper((string) ($this->payload['currency'] ?? ''));
                if (!is_numeric($receivedAmount) || $receivedCurrency === '') {
                    Log::error('Paid webhook rejected: amount or currency is missing', [
                        'payment_id' => $payment->id,
                        'provider' => $this->provider,
                    ]);
                    return;
                }
                if (strtoupper((string) $payment->currency) !== $receivedCurrency
                    || (int) round((float) $payment->amount * 100) !== (int) round((float) $receivedAmount * 100)) {
                    Log::critical('Paid webhook rejected: amount or currency mismatch', [
                        'payment_id' => $payment->id,
                        'expected_amount' => $payment->amount,
                        'received_amount' => $receivedAmount,
                        'expected_currency' => $payment->currency,
                        'received_currency' => $receivedCurrency,
                    ]);
                    return;
                }
            }

            if ($payment->status === $status
                || $payment->status === 'refunded'
                || ($payment->status === 'paid' && $status === 'failed')) {
                return; // idempotent — already processed
            }

            $payment->update([
                'status'  => $status,
                'paid_at' => $status === 'paid' ? now() : $payment->paid_at,
            ]);

            $order = Order::whereKey($payment->order_id)->lockForUpdate()->first();
            $wasPaymentReady = $order?->isPaymentReadyForDriver() ?? false;
            $latePaymentForCancelledOrder = $order && $order->status === 'cancelled' && $status === 'paid';
            if ($latePaymentForCancelledOrder) {
                $meta = $order->meta ?? [];
                $meta['late_payment_review_required'] = true;
                $meta['late_payment_id'] = $payment->id;
                $order->update(['meta' => $meta]);
                Log::critical('Gateway payment succeeded after order cancellation; refund review required', [
                    'order_id' => $order->id,
                    'payment_id' => $payment->id,
                ]);
            }
            if ($order && !$latePaymentForCancelledOrder && $order->payment_status !== 'refunded'
                && !($order->payment_status === 'paid' && $status === 'failed')) {
                $order->update(['payment_status' => $status]);
            }

            if ($status === 'paid') {
                if ($order && !$wasPaymentReady && $order->isDispatchableToDrivers()) {
                    app(\App\Services\OrderDispatchService::class)->publish($order);
                }

                // Notify customer of successful payment
                if ($payment->customer_id) {
                    try {
                        NotificationService::send(
                            user: $payment->customer_id,
                            type: 'payment.received',
                            title: 'Payment Confirmed',
                            body: "Payment of ₱{$payment->amount} for order #{$payment->order_id} was successful.",
                            data: [
                                'payment_id' => $payment->id,
                                'order_id'   => $payment->order_id,
                                'amount'     => $payment->amount,
                            ],
                            channel: 'push'
                        );
                    } catch (\Throwable $e) {
                        Log::warning('Payment notification failed', ['payment_id' => $payment->id, 'error' => $e->getMessage()]);
                    }
                }
            }

            Log::info('ProcessPaymentWebhookJob: payment updated', [
                'payment_id' => $payment->id,
                'status'     => $status,
                'provider'   => $this->provider,
            ]);
        });
    }

    private function resolveStatus(string $providerStatus): ?string
    {
        return match (strtoupper($providerStatus)) {
            // Xendit invoice statuses
            'PAID', 'SETTLED'                            => 'paid',
            'EXPIRED'                                    => 'failed',
            // PayMongo statuses
            'SUCCEEDED', 'COMPLETED', 'SUCCESS'          => 'paid',
            'FAILED', 'FAILURE', 'DECLINED'              => 'failed',
            'REFUNDED', 'REVERSED'                       => 'refunded',
            default                                      => null,
        };
    }

    private function isTransferEvent(): bool
    {
        $eventType = $this->payload['event_type'] ?? '';
        return str_contains($eventType, 'transfer');
    }

    private function handleTransferStatus(string $transferId, string $status): void
    {
        // Check if this transfer is a mission reward payout
        $payout = MissionRewardPayout::where('paymongo_transfer_id', $transferId)
            ->orWhere('paymongo_reference', $transferId)
            ->first();

        // Also try external_id from payload
        if (!$payout && !empty($this->payload['external_id'])) {
            $payout = MissionRewardPayout::where('paymongo_reference', $this->payload['external_id'])->first();
        }

        if ($payout) {
            // Idempotency: do not re-process if already successful (MissionRewardPayoutService also guards, but double-check here)
            if ($payout->isSuccessful() && $status === 'paid') {
                Log::info('ProcessPaymentWebhookJob: mission reward already successful — idempotent skip', [
                    'payout_id' => $payout->id,
                    'transfer_id' => $transferId,
                ]);
                return;
            }
            if ($status === 'paid') {
                try {
                    MissionRewardPayoutService::confirmPayoutSuccess($transferId, $this->payload);
                    NotificationService::send(
                        user: $payout->rider_user_id,
                        type: 'mission.reward',
                        title: 'Mission Reward Reimbursed',
                        body: '₱' . number_format((float) $payout->reward_amount, 2) . ' has been credited to your wallet via PayMongo.',
                        data: [
                            'mission_reward_payout_id' => $payout->id,
                            'mission_id' => $payout->mission_id,
                            'amount' => $payout->reward_amount,
                            'paymongo_reference' => $payout->paymongo_reference,
                        ],
                        channel: 'push'
                    );
                } catch (\Throwable $e) {
                    Log::error('Mission reward payout webhook confirmation failed', [
                        'payout_id' => $payout->id,
                        'transfer_id' => $transferId,
                        'error' => $e->getMessage(),
                    ]);
                }
            } elseif ($status === 'failed') {
                MissionRewardPayoutService::markPayoutFailed($transferId, 'PayMongo transfer failed via webhook', $this->payload);
            }

            Log::info('ProcessPaymentWebhookJob: mission reward transfer status', [
                'transfer_id' => $transferId,
                'payout_id' => $payout->id ?? null,
                'status' => $status,
                'provider' => $this->provider,
            ]);
            return;
        }

        // Regular withdrawal transfer handling
        $withdrawal = WalletWithdrawal::query()
            ->where('provider', $this->provider)
            ->where(function ($query) use ($transferId) {
                $query->where('gateway_reference', $transferId)
                    ->orWhere('external_reference', $transferId);
            })
            ->first();
        if ($withdrawal) {
            WalletWithdrawalService::applyGatewayStatus(
                $withdrawal,
                $status === 'paid' ? 'succeeded' : $status,
                $this->payload,
            );
            return;
        }

        if ($status === 'failed') {
            Log::warning('ProcessPaymentWebhookJob: PayMongo transfer failed with no matching payout', [
                'transfer_id' => $transferId,
                'provider'    => $this->provider,
            ]);
        }

        Log::info('ProcessPaymentWebhookJob: PayMongo transfer status', [
            'transfer_id' => $transferId,
            'status'      => $status,
            'provider'    => $this->provider,
        ]);
    }

    public function failed(\Throwable $e): void
    {
        Log::error('ProcessPaymentWebhookJob failed', [
            'provider' => $this->provider,
            'error'    => $e->getMessage(),
            'payload'  => $this->payload,
        ]);
    }
}
