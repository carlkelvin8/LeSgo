<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Partner;
use App\Models\User;
use App\Models\WalletTransaction;

/**
 * Pays out an online-paid order (LesPay wallet, GCash, Maya, card, Xendit)
 * when it is completed. The customer's money is already with the platform, so:
 *  - the store's wallet gets the item subtotal (what the merchant app shows as
 *    "Credited to E-Wallet"), and
 *  - the rider's wallet gets the delivery fare. The platform fee was already
 *    taken from the rider as the hold on accept, so the rider nets driver_share.
 * Cash orders are not touched: the rider collects the money in person.
 * Each credit is idempotent per order (meta flag + ledger lookup).
 */
class OrderSettlementService
{
    public const ONLINE_METHODS = ['wallet', 'gcash', 'maya', 'card', 'xendit'];

    public static function isOnlinePaid(Order $order): bool
    {
        return in_array(strtolower((string) $order->payment_method), self::ONLINE_METHODS, true)
            && strtolower((string) $order->payment_status) === 'paid';
    }

    /**
     * Item subtotal the store earns, priced like the customer was charged.
     */
    public static function merchantAmount(Order $order): float
    {
        // Same rule as OrderWalletPaymentService: the customer only pays for
        // items on LesEat/LesBuy orders, so only those carry store earnings.
        $serviceCode = strtoupper((string) $order->service?->code);
        if (! $order->partner_id || ! in_array($serviceCode, ['LESEAT', 'LESBUY'], true)) {
            return 0.0;
        }

        $amount = (float) $order->lesbuyItems()
            ->selectRaw('COALESCE(SUM(COALESCE(actual_price, estimated_price, 0) * quantity), 0) as aggregate')
            ->value('aggregate');

        return is_finite($amount) && $amount > 0 ? round($amount, 2) : 0.0;
    }

    public static function driverAmount(Order $order): float
    {
        $fare = (float) ($order->actual_fare ?? $order->estimated_fare ?? 0);

        return is_finite($fare) && $fare > 0 ? round($fare, 2) : 0.0;
    }

    /**
     * Credit the store and the rider for a completed online-paid order.
     * Mutates $order->meta; the caller saves the order.
     */
    public static function settleCompletedOrder(Order $order): void
    {
        if (! self::isOnlinePaid($order)) {
            return;
        }

        $meta = is_array($order->meta) ? $order->meta : [];

        if (empty($meta['merchant_settled'])) {
            $amount = self::merchantAmount($order);
            $owner = $order->partner_id ? Partner::find($order->partner_id)?->user : null;
            if ($amount > 0 && $owner) {
                self::creditOnce($owner, $amount, "Store earnings for order #{$order->id}", $order);
                $meta['merchant_settled'] = true;
                $meta['merchant_settled_amount'] = $amount;
                $meta['merchant_settled_at'] = now()->toIso8601String();
            }
        }

        if (empty($meta['driver_settled'])) {
            $amount = self::driverAmount($order);
            $order->loadMissing('driverProfile.user');
            $driver = $order->driverProfile?->user;
            if ($amount > 0 && $driver) {
                self::creditOnce($driver, $amount, "Delivery fare for order #{$order->id}", $order);
                $meta['driver_settled'] = true;
                $meta['driver_settled_amount'] = $amount;
                $meta['driver_settled_at'] = now()->toIso8601String();
            }
        }

        $order->meta = $meta;
    }

    private static function creditOnce(User $user, float $amount, string $description, Order $order): void
    {
        WalletValidationService::ensureWalletExists($user);
        $walletId = $user->wallet()->value('id');

        $already = WalletTransaction::query()
            ->where('wallet_id', $walletId)
            ->where('type', 'credit')
            ->where('source_type', Order::class)
            ->where('source_id', $order->id)
            ->where('description', $description)
            ->exists();

        if (! $already) {
            WalletService::credit($user, $amount, $description, Order::class, $order->id);
        }
    }
}
