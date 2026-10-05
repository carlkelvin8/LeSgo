<?php

namespace App\Console\Commands;

use App\Models\Order;
use App\Services\OrderDispatchService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProcessScheduledOrders extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'orders:process-scheduled
                          {--dry-run : Show what would be processed without actually processing}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Process scheduled orders that are ready for driver assignment';

    /**
     * Execute the console command.
     */
    public function handle(OrderDispatchService $orderDispatchService): int
    {
        $isDryRun = $this->option('dry-run');

        $this->info('🔍 Checking for scheduled orders ready to be assigned...');

        // Find all scheduled orders where scheduled_delivery_time has passed
        $orders = Order::where('status', 'scheduled')
            ->where(function ($query) {
                // Handle both scheduled_delivery_time and scheduled_at
                $query->where(function ($q) {
                    $q->whereNotNull('scheduled_delivery_time')
                        ->where('scheduled_delivery_time', '<=', now());
                })->orWhere(function ($q) {
                    $q->whereNull('scheduled_delivery_time')
                        ->whereNotNull('scheduled_at')
                        ->where('scheduled_at', '<=', now());
                });
            })
            ->get();

        if ($orders->isEmpty()) {
            $this->info('✅ No scheduled orders ready for assignment at this time.');

            return Command::SUCCESS;
        }

        $this->info("📦 Found {$orders->count()} scheduled order(s) ready for assignment:");
        $processed = 0;

        foreach ($orders as $order) {
            $scheduledFor = $order->scheduled_delivery_time ?? $order->scheduled_at;
            $scheduledTime = $scheduledFor?->format('Y-m-d H:i:s') ?? 'unknown time';
            $orderInfo = "Order #{$order->id} (scheduled for {$scheduledTime})";

            if ($isDryRun) {
                $this->line("  [DRY RUN] Would process: {$orderInfo}");

                continue;
            }

            try {
                $readyOrder = DB::transaction(function () use ($order) {
                    $lockedOrder = Order::query()
                        ->whereKey($order->id)
                        ->lockForUpdate()
                        ->first();

                    if (! $lockedOrder || $lockedOrder->status !== 'scheduled') {
                        return null;
                    }

                    $scheduledFor = $lockedOrder->scheduled_delivery_time
                        ?? $lockedOrder->scheduled_at;
                    if (! $scheduledFor || $scheduledFor->isFuture()) {
                        return null;
                    }

                    $lockedOrder->update(['status' => 'pending']);

                    return $lockedOrder;
                }, 3);

                if (! $readyOrder) {
                    $this->line("  ↪ Skipped (already processed): {$orderInfo}");

                    continue;
                }

                $orderDispatchService->publish($readyOrder);
                $processed++;

                $this->line("  ✅ Processed: {$orderInfo}");

                Log::info('Scheduled order processed', [
                    'order_id' => $order->id,
                    'scheduled_time' => $scheduledTime,
                    'customer_id' => $order->customer_id,
                    'service_id' => $order->service_id,
                ]);
            } catch (\Exception $e) {
                $this->error("  ❌ Failed to process {$orderInfo}: {$e->getMessage()}");

                Log::error('Failed to process scheduled order', [
                    'order_id' => $order->id,
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString(),
                ]);
            }
        }

        if ($isDryRun) {
            $this->warn('🔸 DRY RUN MODE: No changes were made. Remove --dry-run to actually process orders.');
        } else {
            $this->info("✅ Processed {$processed} scheduled order(s) successfully.");
        }

        return Command::SUCCESS;
    }
}
