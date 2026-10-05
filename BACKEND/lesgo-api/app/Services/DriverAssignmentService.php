<?php

namespace App\Services;

use App\Jobs\NotifyDriverAssignedJob;
use App\Models\DriverProfile;
use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class DriverAssignmentService
{
    /**
     * Auto-assign the best available driver to an order
     */
    public function autoAssignDriver(Order $order): ?User
    {
        $order->refresh();
        if (! $order->isDispatchableToDrivers()) {
            return null;
        }

        // Find available drivers within radius
        $availableDrivers = $this->findAvailableDrivers($order);

        if ($availableDrivers->isEmpty()) {
            return null;
        }

        // Score and rank drivers
        $rankedDrivers = $this->rankDriversByScore($order, $availableDrivers);

        foreach ($rankedDrivers as $driver) {
            try {
                if (! $this->assignDriverToOrder($order, $driver)) {
                    continue;
                }

                NotifyDriverAssignedJob::dispatch($order)->onQueue('notifications');

                return $driver;
            } catch (\RuntimeException) {
                // A driver's wallet or availability can change after candidate
                // selection. Try the next ranked candidate instead of failing
                // the entire order assignment.
                continue;
            }
        }

        return null;
    }

    /**
     * Find available drivers within pickup radius
     */
    private function findAvailableDrivers(Order $order, int $radiusKm = 10): \Illuminate\Support\Collection
    {
        return User::query()
            ->where('role', 'driver')
            ->whereHas('driverProfile', function ($query) use ($order) {
                $query->where('status', 'active')
                    ->supportsVehicleType($order->vehicle_type);
            })
            ->whereHas('wallet', function ($query) {
                // Use existing wallet validation
                $threshold = WalletValidationService::getMinimumThreshold();
                $query->where('balance', '>=', $threshold);
            })
            ->whereHas('latestDriverLocation', function ($query) use ($order, $radiusKm) {
                $query->online()
                    ->recent()
                    ->nearby((float) $order->pickup_lat, (float) $order->pickup_lng, $radiusKm);
            })
            ->whereDoesntHave('driverProfile.orders', function ($query) {
                $query->active();
            })
            ->with(['driverProfile', 'wallet', 'latestDriverLocation'])
            ->get();
    }

    /**
     * Rank drivers by multiple factors
     */
    private function rankDriversByScore(Order $order, \Illuminate\Support\Collection $drivers): \Illuminate\Support\Collection
    {
        return $drivers->map(function ($driver) use ($order) {
            $score = 0;

            // Distance score (closer = better)
            $distance = $this->calculateDistance($order, $driver);
            $distanceScore = max(0, 100 - ($distance * 10)); // 10 points per km penalty
            $score += $distanceScore * 0.4; // 40% weight

            // Rating score
            $rating = $driver->driverProfile->rating ?? 4.0;
            $ratingScore = ($rating / 5) * 100;
            $score += $ratingScore * 0.3; // 30% weight

            // Completion rate score
            $completionRate = $this->getDriverCompletionRate($driver);
            $score += $completionRate * 0.2; // 20% weight

            // Availability score (how long since last order)
            $availabilityScore = $this->getAvailabilityScore($driver);
            $score += $availabilityScore * 0.1; // 10% weight

            $driver->assignment_score = $score;

            return $driver;
        })->sortByDesc('assignment_score');
    }

    /**
     * Assign driver to order with validation
     */
    private function assignDriverToOrder(Order $order, User $driver): bool
    {
        return DB::transaction(function () use ($order, $driver) {
            if (!RegistrationFeeService::canAccessOperationalFeatures($driver)) {
                return false;
            }
            $driverProfile = DriverProfile::query()
                ->whereKey($driver->driverProfile->id)
                ->lockForUpdate()
                ->first();

            if (! $driverProfile || $driverProfile->status !== 'active') {
                return false;
            }

            // Double-check driver is still available
            if (! WalletValidationService::hasSufficientBalance($driver)) {
                return false;
            }

            // Lock both sides of the assignment. Concurrent assignment jobs for
            // the same driver serialize on the profile row and cannot double-book.
            if ($driverProfile->orders()->active()->exists()) {
                return false;
            }

            $lockedOrder = Order::query()
                ->whereKey($order->id)
                ->lockForUpdate()
                ->first();

            if (! $lockedOrder || ! $lockedOrder->isDispatchableToDrivers()) {
                return false;
            }

            OrderDriverWalletService::chargeDriverOnAccept($driver, $lockedOrder);

            // Assign driver
            $lockedOrder->update([
                'driver_id' => $driverProfile->id,
                'status' => 'accepted',
                'accepted_at' => now(),
            ]);

            $order->setRawAttributes($lockedOrder->getAttributes(), true);

            // Clear cache
            CacheService::forgetByPattern("orders:user:{$order->customer_id}:list:*");

            return true;
        });
    }

    /**
     * Calculate distance between order pickup and driver
     */
    private function calculateDistance(Order $order, User $driver): float
    {
        $driverLocation = $driver->latestDriverLocation;
        if (! $driverLocation) {
            return 999; // Very high penalty for no location
        }

        $earthRadius = 6371; // km

        $latDelta = deg2rad($driverLocation->latitude - $order->pickup_lat);
        $lonDelta = deg2rad($driverLocation->longitude - $order->pickup_lng);

        $a = sin($latDelta / 2) * sin($latDelta / 2) +
             cos(deg2rad($order->pickup_lat)) * cos(deg2rad($driverLocation->latitude)) *
             sin($lonDelta / 2) * sin($lonDelta / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }

    /**
     * Get driver completion rate
     */
    private function getDriverCompletionRate(User $driver): float
    {
        $cacheKey = "driver_completion_rate:{$driver->id}";

        return Cache::remember($cacheKey, 3600, function () use ($driver) {
            $totalOrders = Order::where('driver_id', $driver->driverProfile->id)->count();

            if ($totalOrders === 0) {
                return 80; // Default score for new drivers
            }

            $completedOrders = Order::where('driver_id', $driver->driverProfile->id)
                ->where('status', 'completed')
                ->count();

            return ($completedOrders / $totalOrders) * 100;
        });
    }

    /**
     * Get availability score based on last activity
     */
    private function getAvailabilityScore(User $driver): float
    {
        $lastOrder = Order::where('driver_id', $driver->driverProfile->id)
            ->latest('completed_at')
            ->first();

        if (! $lastOrder || ! $lastOrder->completed_at) {
            return 100; // Fully available
        }

        $minutesSinceLastOrder = now()->diffInMinutes($lastOrder->completed_at);

        // More available if longer since last order (up to 2 hours)
        return min(100, ($minutesSinceLastOrder / 120) * 100);
    }
}
