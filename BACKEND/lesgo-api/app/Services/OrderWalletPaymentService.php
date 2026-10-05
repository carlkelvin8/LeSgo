<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class OrderWalletPaymentService
{
    public static function resolvePayableAmount(Order $order): float
    {
        $order->refresh();
        // Client-controlled order metadata is display/analytics data only. It
        // must never be the authority for wallet debits or gateway invoices.
        $fare = (float) ($order->actual_fare ?? $order->estimated_fare ?? 0);
        $serviceCode = strtoupper((string) $order->service?->code);
        $itemsTotal = in_array($serviceCode, ['LESEAT', 'LESBUY'], true)
            ? (float) $order->lesbuyItems()
                ->selectRaw('COALESCE(SUM(COALESCE(actual_price, estimated_price, 0) * quantity), 0) as aggregate')
                ->value('aggregate')
            : 0.0;
        $discount = (float) ($order->discount_amount ?? 0);

        if (!is_finite($fare) || $fare < 0 || !is_finite($itemsTotal) || $itemsTotal < 0
            || !is_finite($discount) || $discount < 0) {
            throw new \RuntimeException('Order contains invalid payable amounts.');
        }

        $grossAmount = round($fare + $itemsTotal, 2);
        if ($discount > $grossAmount) {
            throw new \RuntimeException('Order discount exceeds the payable amount.');
        }

        return round($grossAmount - $discount, 2);
    }

    /**
     * Debit LesPay wallet and mark order as paid.
     *
     * @throws \RuntimeException when balance is insufficient or amount invalid
     */
    public static function payWithWallet(Order $order): Payment
    {
        $amount = self::resolvePayableAmount($order);

        if ($amount <= 0) {
            throw new \RuntimeException('Invalid order amount for LesPay payment.');
        }

        $customer = $order->customer ?? User::findOrFail($order->customer_id);

        return DB::transaction(function () use ($order, $customer, $amount) {
            WalletService::debit(
                $customer,
                $amount,
                "LesPay payment for order #{$order->id}",
                Order::class,
                $order->id,
            );

            $payment = Payment::create([
                'order_id'    => $order->id,
                'customer_id' => $customer->id,
                'partner_id'  => $order->partner_id,
                'amount'      => $amount,
                'currency'    => 'PHP',
                'method'      => 'wallet',
                'status'      => 'paid',
                'provider'    => 'lespay',
                'paid_at'     => now(),
                'meta'        => ['source' => 'order_checkout'],
            ]);

            $order->update([
                'payment_status' => 'paid',
                'payment_method' => 'wallet',
            ]);

            CacheService::forgetByPattern("wallets:user:{$customer->id}:*");

            return $payment;
        });
    }
}
