<?php

namespace App\Services;

use App\Models\Order;
use App\Models\User;
use App\Models\WalletTransaction;

class OrderDriverWalletService
{
    /**
     * Amount deducted from the driver's wallet when accepting a booking.
     */
    public static function resolveBookingChargeAmount(Order $order): float
    {
        return RiderCommissionService::resolveShippingFee($order);
    }

    /**
     * Debit the driver's wallet for the booking total (idempotent per order).
     *
     * @throws \RuntimeException when balance is insufficient
     */
    public static function chargeDriverOnAccept(User $driver, Order $order): void
    {
        if (!$driver->isDriver()) {
            throw new \RuntimeException('Only drivers can accept paid bookings.');
        }

        $amount = self::resolveBookingChargeAmount($order);
        if ($amount <= 0) {
            return;
        }

        $meta = is_array($order->meta) ? $order->meta : [];
        $chargedDriverId = (int) ($meta['driver_wallet_charged_driver_id'] ?? 0);
        if ((float) ($meta['driver_wallet_charged_amount'] ?? 0) > 0
            && ($chargedDriverId === (int) $driver->id || $chargedDriverId === 0)
            && empty($meta['driver_wallet_refunded'])) {
            return;
        }

        WalletValidationService::ensureWalletExists($driver);

        $balance = WalletValidationService::getWalletBalance($driver);
        if ($balance < $amount) {
            throw new \RuntimeException(
                sprintf(
                    'Insufficient wallet balance. Shipping fee: PHP %.2f. Available: PHP %.2f.',
                    $amount,
                    $balance
                )
            );
        }

        $chargeTransaction = WalletService::debit(
            $driver,
            $amount,
            "Shipping fee hold for order #{$order->id}",
            Order::class,
            $order->id,
        );

        $meta['driver_wallet_charged_amount'] = $amount;
        $meta['driver_wallet_charged_at']     = now()->toIso8601String();
        $meta['driver_wallet_charged_driver_id'] = $driver->id;
        $meta['driver_wallet_charged_transaction_id'] = $chargeTransaction->id;
        $meta['driver_wallet_refunded'] = false;
        $order->meta = $meta;
    }

    /**
     * Refund the driver's booking charge when an accepted order is cancelled.
     */
    public static function refundDriverOnCancel(Order $order): void
    {
        $order->loadMissing('driverProfile.user');

        $meta = is_array($order->meta) ? $order->meta : [];
        $charged = (float) ($meta['driver_wallet_charged_amount'] ?? 0);
        $chargeTransactionId = (int) ($meta['driver_wallet_charged_transaction_id'] ?? 0);

        if ($charged <= 0 || !empty($meta['driver_wallet_refunded'])) {
            return;
        }

        $chargedDriverId = (int) ($meta['driver_wallet_charged_driver_id'] ?? 0);
        $driver = $chargedDriverId > 0
            ? User::find($chargedDriverId)
            : $order->driverProfile?->user;
        if (!$driver) {
            return;
        }
        WalletValidationService::ensureWalletExists($driver);
        $walletId = $driver->wallet?->id;

        $alreadyRefunded = WalletTransaction::query()
            ->where('type', 'credit')
            ->where('source_type', Order::class)
            ->where('source_id', $order->id)
            ->where('wallet_id', $walletId)
            ->where('description', $chargeTransactionId > 0
                ? "Refund for cancelled order #{$order->id} (charge #{$chargeTransactionId})"
                : "Refund for cancelled order #{$order->id}")
            ->exists();

        if ($alreadyRefunded) {
            $meta['driver_wallet_refunded'] = true;
            $meta['driver_wallet_refunded_at'] = now()->toIso8601String();
            $meta['driver_wallet_charged_amount'] = 0.0;
            $meta['driver_wallet_charged_driver_id'] = null;
            $meta['driver_wallet_charged_transaction_id'] = null;
            $order->meta = $meta;
            $order->saveQuietly();
            return;
        }

        WalletService::credit(
            $driver,
            $charged,
            "Refund for cancelled order #{$order->id}".
                ($chargeTransactionId > 0 ? " (charge #{$chargeTransactionId})" : ''),
            Order::class,
            $order->id,
        );

        $meta['driver_wallet_refunded']    = true;
        $meta['driver_wallet_refunded_at'] = now()->toIso8601String();
        $meta['driver_wallet_charged_amount'] = 0.0;
        $meta['driver_wallet_charged_driver_id'] = null;
        $meta['driver_wallet_charged_transaction_id'] = null;
        $order->meta = $meta;
        $order->saveQuietly();
    }
}
