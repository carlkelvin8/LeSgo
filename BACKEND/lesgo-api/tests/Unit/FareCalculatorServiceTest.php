<?php

namespace Tests\Unit;

use App\Models\Service;
use App\Services\FareCalculatorService;
use PHPUnit\Framework\TestCase;

class FareCalculatorServiceTest extends TestCase
{
    private FareCalculatorService $calculator;

    private Service $lesride;

    protected function setUp(): void
    {
        parent::setUp();

        $this->calculator = new FareCalculatorService;
        $this->lesride = new Service([
            'code' => 'LESRIDE',
            'base_fare' => 60,
            'per_km_rate' => 15,
            'minimum_fare' => 60,
        ]);
    }

    public function test_lesride_base_fare_covers_the_first_three_kilometers(): void
    {
        $this->assertSame(60.0, $this->calculator->calculate($this->lesride, 0)['total']);
        $this->assertSame(60.0, $this->calculator->calculate($this->lesride, 3)['total']);
    }

    public function test_lesride_charges_fifteen_pesos_per_kilometer_after_three_kilometers(): void
    {
        $fourKm = $this->calculator->calculate($this->lesride, 4);
        $fivePointFiveKm = $this->calculator->calculate($this->lesride, 5.5);

        $this->assertSame(15.0, $fourKm['distance_fare']);
        $this->assertSame(75.0, $fourKm['total']);
        $this->assertSame(37.5, $fivePointFiveKm['distance_fare']);
        $this->assertSame(97.5, $fivePointFiveKm['total']);
    }

    public function test_lesride_ignores_delivery_weight_surcharges(): void
    {
        $fare = $this->calculator->calculate($this->lesride, 4, 0, 25);

        $this->assertSame(0.0, $fare['weight_surcharge']);
        $this->assertSame(75.0, $fare['total']);
    }

    public function test_lesride_thirty_kilometer_boundary_is_four_hundred_sixty_five_pesos(): void
    {
        $fare = $this->calculator->calculate($this->lesride, 30);

        $this->assertSame(405.0, $fare['distance_fare']);
        $this->assertSame(465.0, $fare['total']);
    }

    public function test_lesgo_rates_are_unchanged(): void
    {
        $lesgo = new Service([
            'code' => 'LESGO',
            'base_fare' => 40,
            'per_km_rate' => 9.5,
            'minimum_fare' => 40,
        ]);

        $fare = $this->calculator->calculate($lesgo, 5);

        $this->assertSame(40.0, $fare['base_fare']);
        $this->assertSame(19.0, $fare['distance_fare']);
        $this->assertSame(59.0, $fare['total']);
    }
}
