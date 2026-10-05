<?php

namespace App\Jobs;

use App\Events\OrderStatusUpdated;
use App\Models\Order;
use App\Services\OrderCancellationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AutoCancelStaleOrdersJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 1;

    /**
     * Cancel orders that have genuinely been available to drivers for too long.
     * Re-check eligibility in the update to avoid racing driver acceptance.
     */
    public function handle(): void
    {
        $cutoff = now()->subMinutes(30);
        $cancelled = 0;

        Order::query()
            ->dispatchableToDrivers()
            ->where('created_at', '<', $cutoff)
            ->select(['id'])
            ->chunkById(200, function ($orders) use (&$cancelled, $cutoff) {
                $ids = $orders->pluck('id')->all();
                $cancelledOrders = DB::transaction(function () use ($ids, $cutoff) {
                    return Order::query()
                        ->whereIn('id', $ids)
                        ->dispatchableToDrivers()
                        ->where('created_at', '<', $cutoff)
                        ->lockForUpdate()
                        ->get()
                        ->map(function (Order $order) {
                            $previousStatus = $order->status;
                            // This branch contains paid cash/wallet orders that
                            // were eligible for driver dispatch. Run the same
                            // cancellation settlement used by customer cancels
                            // before making the order terminal.
                            OrderCancellationService::process($order);
                            $order->update([
                                'status' => 'cancelled',
                                'cancel_reason' => 'Auto-cancelled: no driver found within 30 minutes.',
                                'cancelled_at' => now(),
                            ]);

                            return [$order, $previousStatus];
                        });
                });

                foreach ($cancelledOrders as [$order, $previousStatus]) {
                    broadcast(new OrderStatusUpdated(
                        $order,
                        $previousStatus,
                        $order->status,
                        ['reason' => $order->cancel_reason]
                    ))->toOthers();
                }

                $cancelled += $cancelledOrders->count();
            });

        // Gateway checkouts are deliberately excluded from driver dispatch.
        // If the customer abandons checkout (or the app cannot report it),
        // close the unpaid order after the same grace period so it cannot
        // consume an active-order slot forever. Do not touch paid payments or
        // future scheduled orders.
        $this->staleUnpaidGatewayOrders($cutoff)
            ->select(['id'])
            ->chunkById(200, function ($orders) use (&$cancelled, $cutoff) {
                $ids = $orders->pluck('id')->all();
                $cancelledOrders = DB::transaction(function () use ($ids, $cutoff) {
                    return $this->staleUnpaidGatewayOrders($cutoff)
                        ->whereIn('id', $ids)
                        ->lockForUpdate()
                        ->get()
                        ->map(function (Order $order) {
                            $previousStatus = $order->status;
                            OrderCancellationService::process($order);
                            $order->update([
                                'status' => 'cancelled',
                                'cancel_reason' => 'Auto-cancelled: digital payment was not completed within 30 minutes.',
                                'cancelled_at' => now(),
                            ]);

                            return [$order, $previousStatus];
                        });
                });

                foreach ($cancelledOrders as [$order, $previousStatus]) {
                    broadcast(new OrderStatusUpdated(
                        $order,
                        $previousStatus,
                        $order->status,
                        ['reason' => $order->cancel_reason]
                    ))->toOthers();
                }

                $cancelled += $cancelledOrders->count();
            });

        Log::info('AutoCancelStaleOrdersJob: completed', ['cancelled_count' => $cancelled]);
    }

    private function staleUnpaidGatewayOrders($cutoff)
    {
        return Order::query()
            ->whereNull('driver_id')
            ->whereIn('status', Order::DRIVER_DISPATCHABLE_STATUSES)
            ->whereIn('payment_method', ['paymongo', 'xendit', 'gcash', 'maya', 'card'])
            ->whereIn('payment_status', ['pending', 'failed'])
            ->where('created_at', '<', $cutoff)
            ->where(function ($scheduleQuery) {
                $scheduleQuery->whereNull('scheduled_at')->orWhere('scheduled_at', '<=', now());
            })
            ->where(function ($scheduleQuery) {
                $scheduleQuery->whereNull('scheduled_delivery_time')->orWhere('scheduled_delivery_time', '<=', now());
            })
            ->whereDoesntHave('payments', function ($paymentQuery) {
                $paymentQuery->where('status', 'paid');
            });
    }
}
