<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Payment;
use App\Models\PaymentRefund;
use App\Models\User;
use App\Jobs\ProcessCancelledGatewayRefundJob;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderCancellationService
{
    /**
     * Refund completed payments and close pending attempts when an order is cancelled.
     */
    public static function process(Order $order): void
    {
        if ($order->status === 'cancelled') {
            return;
        }

        DB::transaction(function () use ($order) {
            $method = strtolower((string) ($order->payment_method ?? 'cash'));
            $paymentStatus = strtolower((string) ($order->payment_status ?? 'pending'));

            if ($method === 'wallet' && $paymentStatus === 'paid') {
                $customer = $order->customer ?? User::find($order->customer_id);

                if ($customer) {
                    $amount = OrderWalletPaymentService::resolvePayableAmount($order);

                    if ($amount > 0) {
                        WalletService::credit(
                            $customer,
                            $amount,
                            "Refund for cancelled order #{$order->id}",
                            Order::class,
                            $order->id,
                        );

                        Payment::where('order_id', $order->id)
                            ->where('status', 'paid')
                            ->update(['status' => 'refunded']);

                        $order->payment_status = 'refunded';
                    }
                }
            } elseif ($paymentStatus === 'paid' && in_array($method, ['card', 'gcash', 'maya', 'paymongo', 'xendit'], true)) {
                $payment = Payment::query()
                    ->where('order_id', $order->id)
                    ->where('status', 'paid')
                    ->lockForUpdate()
                    ->latest('id')
                    ->first();

                if ($payment) {
                    $refund = PaymentRefund::query()
                        ->where('payment_id', $payment->id)
                        ->whereIn('status', PaymentRefund::RESERVED_STATUSES)
                        ->first();

                    if (! $refund) {
                        $reference = $payment->provider_reference
                            ?? data_get($payment->meta, 'payment_request_id');
                        if (! $reference || ! in_array(strtolower((string) $payment->provider), ['paymongo', 'xendit'], true)) {
                            throw new \RuntimeException('The completed gateway payment cannot be refunded automatically.');
                        }

                        $refund = PaymentRefund::create([
                            'payment_id' => $payment->id,
                            'requested_by' => $order->customer_id,
                            'amount' => $payment->amount,
                            'currency' => $payment->currency ?? 'PHP',
                            'provider' => strtolower($payment->provider),
                            'payment_reference' => $reference,
                            'idempotency_key' => 'cancel-order-'.$order->id.'-payment-'.$payment->id,
                            'status' => 'processing',
                            'reason' => 'REQUESTED_BY_CUSTOMER',
                            'meta' => ['source' => 'order_cancellation'],
                        ]);
                    }

                    ProcessCancelledGatewayRefundJob::dispatch($refund->id)->afterCommit();
                }
            } elseif (in_array($paymentStatus, ['pending', 'failed'], true)) {
                Payment::where('order_id', $order->id)
                    ->where('status', 'pending')
                    ->update(['status' => 'failed']);

                if ($paymentStatus === 'pending') {
                    $order->payment_status = 'failed';
                }
            }

            OrderDriverWalletService::refundDriverOnCancel($order);

            CacheService::forgetByPattern("wallets:user:{$order->customer_id}:*");

            if ($order->driverProfile?->user_id) {
                CacheService::forgetByPattern("wallets:user:{$order->driverProfile->user_id}:*");
            }
        });
    }
}
