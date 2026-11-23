<?php

namespace App\Jobs;

use App\Models\Order;
use App\Services\NotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Push an alert to the merchant (owner and staff) when a new order arrives,
 * so they are alarmed even when the app is closed or in the background.
 */
class NotifyMerchantNewOrderJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 15;

    public function __construct(public Order $order) {}

    public function handle(): void
    {
        $this->order->refresh()->loadMissing(['partner.user', 'partner.staff']);

        $partner = $this->order->partner;
        if (! $partner || in_array(strtolower((string) $this->order->status), ['cancelled', 'rejected'], true)) {
            return;
        }

        $recipientIds = $partner->staff->pluck('user_id')
            ->prepend($partner->user_id)
            ->filter()
            ->unique();

        $ref = $this->order->reference_number ?? '#'.$this->order->id;

        $message = $this->order->status === 'pending'
            ? "Order {$ref} is waiting for your acceptance."
            : "Please check order {$ref} in your order queue.";

        foreach ($recipientIds as $userId) {
            try {
                NotificationService::send(
                    user: (int) $userId,
                    type: 'new_merchant_order',
                    title: 'New Order!',
                    body: $message,
                    data: [
                        'type' => 'new_merchant_order',
                        'order_id' => $this->order->id,
                        'partner_id' => $partner->id,
                    ],
                    channel: 'push'
                );
            } catch (\Throwable $e) {
                Log::warning('NotifyMerchantNewOrderJob: notification failed', [
                    'order_id' => $this->order->id,
                    'user_id' => $userId,
                    'error' => $e->getMessage(),
                ]);
            }
        }
    }

    public function failed(\Throwable $e): void
    {
        Log::error('NotifyMerchantNewOrderJob failed', [
            'order_id' => $this->order->id,
            'error' => $e->getMessage(),
        ]);
    }
}
