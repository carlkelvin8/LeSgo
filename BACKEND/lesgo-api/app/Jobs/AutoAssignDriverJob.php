<?php

namespace App\Jobs;

use App\Models\Order;
use App\Services\DriverAssignmentService;
use App\Services\NotificationService;
use App\Services\RealtimeService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class AutoAssignDriverJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        private Order $order,
        private int $attemptNumber = 1
    ) {}

    public function handle(
        DriverAssignmentService $assignmentService,
        RealtimeService $realtimeService
    ): void {
        try {
            // Re-check eligibility because payment, schedule, manual-assignment,
            // and order status can change while the job is waiting in the queue.
            $this->order->refresh();

            if (! $this->order->isDispatchableToDrivers()) {
                Log::info('AutoAssignDriverJob: Order no longer dispatchable', [
                    'order_id' => $this->order->id,
                    'status' => $this->order->status,
                ]);

                return;
            }

            // Attempt auto-assignment
            $assignedDriver = $assignmentService->autoAssignDriver($this->order);

            if ($assignedDriver) {
                Log::info('AutoAssignDriverJob: Driver assigned successfully', [
                    'order_id' => $this->order->id,
                    'driver_id' => $assignedDriver->id,
                    'attempt' => $this->attemptNumber,
                ]);

                // Broadcast real-time update
                $realtimeService->broadcastOrderStatusUpdate($this->order, 'pending', [
                    'auto_assigned' => true,
                    'driver_id' => $assignedDriver->id,
                    'attempt_number' => $this->attemptNumber,
                ]);

            } else {
                Log::warning('AutoAssignDriverJob: No available drivers found', [
                    'order_id' => $this->order->id,
                    'attempt' => $this->attemptNumber,
                ]);

                // Retry with expanding radius or delay
                if ($this->attemptNumber < 3) {
                    // Retry in 2 minutes with expanded search
                    AutoAssignDriverJob::dispatch($this->order, $this->attemptNumber + 1)
                        ->delay(now()->addMinutes(2))
                        ->onQueue('driver-assignment');
                } else {
                    // Final attempt failed — notify customer
                    Log::error('AutoAssignDriverJob: All assignment attempts failed', [
                        'order_id' => $this->order->id,
                        'total_attempts' => $this->attemptNumber,
                    ]);

                    $this->order->loadMissing('customer');
                    if ($this->order->customer) {
                        NotificationService::send(
                            user: $this->order->customer,
                            type: 'driver_assignment_failed',
                            title: 'Finding Driver',
                            body: "We're still looking for a driver for your order #{$this->order->id}. Please wait a moment or try again.",
                            data: [
                                'order_id' => $this->order->id,
                                'status' => 'retry_needed',
                            ],
                            channel: 'push'
                        );
                    }
                }
            }

        } catch (\Exception $e) {
            Log::error('AutoAssignDriverJob failed', [
                'order_id' => $this->order->id,
                'attempt' => $this->attemptNumber,
                'error' => $e->getMessage(),
            ]);

            throw $e; // Let Laravel handle retry logic
        }
    }

    public function failed(\Throwable $e): void
    {
        Log::error('AutoAssignDriverJob permanently failed', [
            'order_id' => $this->order->id,
            'attempt' => $this->attemptNumber,
            'error' => $e->getMessage(),
        ]);
    }
}
