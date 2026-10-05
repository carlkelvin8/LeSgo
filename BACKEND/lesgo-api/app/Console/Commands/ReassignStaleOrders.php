<?php

namespace App\Console\Commands;

use App\Models\Order;
use App\Services\OrderDriverWalletService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Detects orders stuck in "accepted" status where the driver hasn't progressed
 * within a configurable timeout. Resets them to "pending" so another driver can pick up.
 *
 * Recommended schedule: every 5 minutes via Laravel scheduler.
 *
 * Usage:
 *   php artisan orders:reassign-stale
 *   php artisan orders:reassign-stale --timeout=15  (minutes)
 *   php artisan orders:reassign-stale --dry-run
 */
class ReassignStaleOrders extends Command
{
    protected $signature = 'orders:reassign-stale
        {--timeout=10 : Minutes before an accepted order is considered stale}
        {--dry-run : Show what would be reassigned without actually doing it}';

    protected $description = 'Reassign orders stuck in accepted status (driver went offline)';

    public function handle(): int
    {
        $timeoutMinutes = (int) $this->option('timeout');
        $dryRun = (bool) $this->option('dry-run');
        $cutoff = now()->subMinutes($timeoutMinutes);

        $staleOrders = Order::where('status', 'accepted')
            ->where('accepted_at', '<', $cutoff)
            ->whereNotNull('driver_id')
            ->get();

        if ($staleOrders->isEmpty()) {
            $this->info('No stale orders found.');
            return self::SUCCESS;
        }

        $this->info("Found {$staleOrders->count()} stale order(s) (accepted > {$timeoutMinutes} min ago).");

        foreach ($staleOrders as $order) {
            $driverName = $order->driverProfile?->user?->name ?? 'Unknown';

            if ($dryRun) {
                $this->line("  [DRY RUN] Order #{$order->id} — accepted by {$driverName} at {$order->accepted_at}");
                continue;
            }

            try {
                DB::transaction(function () use ($order) {
                    // Refund the driver's shipping fee hold
                    OrderDriverWalletService::refundDriverOnCancel($order);

                    // Reset order to pending so it appears in available orders again
                    $order->update([
                        'status'      => 'pending',
                        'driver_id'   => null,
                        'accepted_at' => null,
                    ]);
                });

                Log::info('Stale order reassigned', [
                    'order_id'   => $order->id,
                    'old_driver' => $driverName,
                    'timeout_min' => $timeoutMinutes,
                ]);

                $this->line("  ✓ Order #{$order->id} reset to pending (was with {$driverName})");
            } catch (\Throwable $e) {
                Log::error('Failed to reassign stale order', [
                    'order_id' => $order->id,
                    'error'    => $e->getMessage(),
                ]);
                $this->error("  ✗ Order #{$order->id} failed: {$e->getMessage()}");
            }
        }

        return self::SUCCESS;
    }
}
