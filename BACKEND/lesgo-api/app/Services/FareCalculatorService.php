<?php

namespace App\Services;

use App\Models\Service;

class FareCalculatorService
{
    public const INCLUDED_DISTANCE_KM = 3.0;

    public const MAX_DISTANCE_KM = 30.0;

    /** Build the authoritative fare breakdown for an order. */
    public function calculate(
        Service $service,
        float $distanceKm,
        float $orderValue = 0.0,
        float $weightKg = 0.0
    ): array {
        $distanceKm = max(0.0, min($distanceKm, self::MAX_DISTANCE_KM));
        $serviceCode = strtoupper((string) ($service->code ?? 'LESGO'));

        $baseFare = $service->base_fare
            ? (float) $service->base_fare
            : 40.0;
        $perKmRate = $service->per_km_rate
            ? (float) $service->per_km_rate
            : ($serviceCode === 'LESGO' ? 9.5 : 10.0);
        $minimumFare = $service->minimum_fare
            ? (float) $service->minimum_fare
            : $baseFare;

        $chargeableDistanceKm = max(
            0.0,
            $distanceKm - self::INCLUDED_DISTANCE_KM
        );
        $distanceFare = round($chargeableDistanceKm * $perKmRate, 2);

        $serviceFee = 0.0;
        if (in_array($serviceCode, ['LESBUY', 'LESEAT'], true)) {
            $serviceFee = match (true) {
                $orderValue <= 500 => 15.0,
                $orderValue <= 1000 => 30.0,
                default => 45.0,
            };
        }

        $weightSurcharge = $serviceCode !== 'LESRIDE' && $weightKg > 5
            ? round(($weightKg - 5) * 10, 2)
            : 0.0;
        $subtotal = $baseFare + $distanceFare + $serviceFee + $weightSurcharge;
        $total = round(max($subtotal, $minimumFare), 2);

        return [
            'base_fare' => round($baseFare, 2),
            'distance_fare' => $distanceFare,
            'service_fee' => $serviceFee,
            'weight_surcharge' => $weightSurcharge,
            'subtotal' => round($subtotal, 2),
            'total' => $total,
            'currency' => 'PHP',
        ];
    }
}
