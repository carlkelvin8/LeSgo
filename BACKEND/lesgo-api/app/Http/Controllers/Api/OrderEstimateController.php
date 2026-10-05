<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Service;
use App\Services\FareCalculatorService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrderEstimateController extends Controller
{
    /**
     * @OA\Post(
     *     path="/api/v1/orders/estimate",
     *     summary="Estimate order fare",
     *     tags={"Orders"},
     *     security={{"sanctum":{}}},
     *
     *     @OA\Response(response=200, description="Fare estimate")
     * )
     */
    public function estimate(
        Request $request,
        FareCalculatorService $fareCalculator
    ): JsonResponse {
        $validated = $request->validate([
            'service_id' => 'required|integer|exists:services,id',
            'pickup' => 'required|array',
            'pickup.lat' => 'required|numeric|between:-90,90',
            'pickup.lng' => 'required|numeric|between:-180,180',
            'dropoff' => 'required|array',
            'dropoff.lat' => 'required|numeric|between:-90,90',
            'dropoff.lng' => 'required|numeric|between:-180,180',
            'estimated_distance_m' => 'nullable|integer|min:0',
            'vehicle_type' => 'nullable|string|in:motor,car,van,bicycle,tricycle',
            'items' => 'nullable|array',
            'order_value' => 'nullable|numeric|min:0',
            'estimated_weight_kg' => 'nullable|numeric|min:0',
        ]);

        $straightLineDistanceM = $this->calculateHaversineDistance(
            $validated['pickup']['lat'],
            $validated['pickup']['lng'],
            $validated['dropoff']['lat'],
            $validated['dropoff']['lng']
        );
        $distanceM = empty($validated['estimated_distance_m'])
            ? $straightLineDistanceM
            : $validated['estimated_distance_m'];

        $service = Service::findOrFail($validated['service_id']);
        $serviceCode = strtoupper((string) ($service->code ?? 'LESGO'));

        if ($serviceCode === 'LESRIDE') {
            if ($straightLineDistanceM < 10) {
                return $this->error('Pickup and destination must be different.', 422);
            }

            // A routed distance cannot be materially shorter than the direct
            // distance. Reject altered or stale client distances before quoting.
            if ($distanceM + 250 < $straightLineDistanceM) {
                return $this->error('The route distance does not match the selected locations.', 422);
            }

            if ($distanceM > 30000) {
                return $this->error('LesRide is currently limited to 30km.', 422);
            }
        }

        // Preserve existing service limits while allowing LesRide to match the
        // order endpoint's documented 30 km limit.
        $maximumDistanceM = $serviceCode === 'LESRIDE' ? 30000 : 25000;
        $distanceM = max(500, min($distanceM, $maximumDistanceM));

        if (! $service->is_active) {
            return $this->error('This service is currently unavailable.', 422);
        }

        if ($serviceCode === 'LESRIDE' && ($validated['vehicle_type'] ?? null) !== 'tricycle') {
            return $this->error('Only the Tricycle option is currently available for LesRide.', 422);
        }

        if ($serviceCode !== 'LESRIDE' && ($validated['vehicle_type'] ?? null) === 'tricycle') {
            return $this->error('The Tricycle option is only available for LesRide.', 422);
        }

        $distanceKm = $distanceM / 1000;
        $orderValue = (float) ($validated['order_value'] ?? 0);
        $weightKg = (float) ($validated['estimated_weight_kg'] ?? 0);
        $fareBreakdown = $fareCalculator->calculate(
            $service,
            $distanceKm,
            $orderValue,
            $weightKg
        );

        // Existing delivery services retain their estimate safety cap. The
        // LesRide matrix tops out below this cap at the 30 km order limit.
        if ($serviceCode !== 'LESRIDE') {
            $fareBreakdown['total'] = min($fareBreakdown['total'], 500.0);
        }

        // Estimated duration (assuming 30 km/h average speed)
        $avgSpeedKmh = 30;
        $estimatedDuration = $distanceKm > 0 ? round(($distanceKm / $avgSpeedKmh) * 60, 2) : 0;

        return $this->success([
            'distance_m' => round($distanceM),
            'distance_km' => round($distanceKm, 2),
            'estimated_fare' => $fareBreakdown['total'],
            'estimated_duration_minutes' => $estimatedDuration,
            'fare_breakdown' => $fareBreakdown,
            'payment_methods' => ['cash', 'gcash', 'maya', 'card', 'wallet', 'xendit'],
            'service' => [
                'id' => $service->id,
                'name' => $service->name,
                'code' => $service->code,
            ],
        ], 'Fare estimated successfully');
    }

    /**
     * Calculate distance between two points using Haversine formula.
     */
    private function calculateHaversineDistance($lat1, $lng1, $lat2, $lng2): float
    {
        $earthRadius = 6371000; // meters

        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLng / 2) * sin($dLng / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }
}
