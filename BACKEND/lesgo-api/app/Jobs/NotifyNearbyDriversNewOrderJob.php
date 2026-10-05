<?php

namespace App\Jobs;

use App\Models\Order;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class NotifyNearbyDriversNewOrderJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;

    public int $backoff = 10;

    public function __construct(public Order $order) {}

    public function handle(): void
    {
        $this->order->refresh();
        $this->order->loadMissing('service');

        if (! $this->order->isDispatchableToDrivers()) {
            Log::info('NotifyNearbyDriversNewOrderJob: Order is not dispatchable', [
                'order_id' => $this->order->id,
                'status' => $this->order->status,
                'payment_status' => $this->order->payment_status,
            ]);

            return;
        }

        $pickupLat = $this->order->pickup_lat;
        $pickupLng = $this->order->pickup_lng;

        if (! $pickupLat || ! $pickupLng) {
            Log::warning('NotifyNearbyDriversNewOrderJob: Missing pickup coordinates', [
                'order_id' => $this->order->id,
            ]);

            return;
        }

        $radiusKm = 10;
        $vehicleType = $this->order->vehicle_type;

        // Find active drivers within radius who have a wallet with sufficient balance
        $nearbyDrivers = User::query()
            ->where('role', 'driver')
            ->whereHas('driverProfile', function ($q) use ($vehicleType) {
                $q->where('status', 'active')
                    ->supportsVehicleType($vehicleType);
            })
            ->whereHas('wallet', function ($q) {
                $threshold = \App\Services\WalletValidationService::getMinimumThreshold();
                $q->where('balance', '>=', $threshold);
            })
            ->whereHas('latestDriverLocation', function ($q) use ($pickupLat, $pickupLng, $radiusKm) {
                $q->online()
                    ->recent()
                    ->nearby((float) $pickupLat, (float) $pickupLng, $radiusKm);
            })
            ->whereDoesntHave('driverProfile.orders', function ($q) {
                $q->active();
            })
            ->with(['driverProfile'])
            ->get();

        if ($nearbyDrivers->isEmpty()) {
            Log::info('NotifyNearbyDriversNewOrderJob: No nearby drivers found', [
                'order_id' => $this->order->id,
            ]);

            return;
        }

        $serviceName = $this->order->service?->name ?? 'Order';
        $pickupAddress = $this->order->pickup_address ?? 'Unknown location';
        $fare = $this->order->estimated_fare
            ? '₱'.number_format($this->order->estimated_fare, 2)
            : '';

        $notified = 0;
        foreach ($nearbyDrivers as $driver) {
            try {
                $body = "New {$serviceName} order available — pickup: {$pickupAddress}";
                if ($fare) {
                    $body .= " — Est. fare: {$fare}";
                }

                NotificationService::send(
                    user: $driver,
                    type: 'new_order_available',
                    title: "New {$serviceName} Order Nearby",
                    body: $body,
                    data: [
                        'order_id' => $this->order->id,
                        'service_id' => $this->order->service_id,
                        'vehicle_type' => $this->order->vehicle_type ?? '',
                        'pickup_address' => $pickupAddress,
                        'estimated_fare' => $this->order->estimated_fare ?? '',
                    ],
                    channel: 'push'
                );
                $notified++;
            } catch (\Exception $e) {
                Log::error('NotifyNearbyDriversNewOrderJob: Failed to notify driver', [
                    'order_id' => $this->order->id,
                    'driver_id' => $driver->id,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        Log::info('NotifyNearbyDriversNewOrderJob: Notified nearby drivers', [
            'order_id' => $this->order->id,
            'drivers_notified' => $notified,
            'total_nearby' => $nearbyDrivers->count(),
        ]);
    }

    public function failed(\Throwable $e): void
    {
        Log::error('NotifyNearbyDriversNewOrderJob permanently failed', [
            'order_id' => $this->order->id,
            'error' => $e->getMessage(),
        ]);
    }
}
