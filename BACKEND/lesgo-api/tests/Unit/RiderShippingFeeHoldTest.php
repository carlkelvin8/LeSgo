<?php

namespace Tests\Unit;

use App\Models\Order;
use App\Services\RiderCommissionService;
use PHPUnit\Framework\TestCase;

class RiderShippingFeeHoldTest extends TestCase
{
    public function test_hold_is_the_basic_tier_platform_cut_of_the_estimate_with_a_ten_peso_floor(): void
    {
        // No rider yet: priced at the Basic tier (rider keeps 70%, platform 30%).
        $order = new Order(['estimated_fare' => 55]);
        $this->assertSame(16.5, RiderCommissionService::resolveShippingFee($order));

        $cheap = new Order(['estimated_fare' => 20]);
        $this->assertSame(10.0, RiderCommissionService::resolveShippingFee($cheap));
    }

    public function test_hold_can_be_priced_on_the_actual_fare_so_overcharges_are_refunded(): void
    {
        $order = new Order(['estimated_fare' => 200, 'actual_fare' => 100]);

        $charged = RiderCommissionService::resolveShippingFee($order);
        $correct = RiderCommissionService::resolveShippingFee($order, 100.0);

        $this->assertSame(60.0, $charged);
        $this->assertSame(30.0, $correct);
        $this->assertGreaterThan(1.0, $charged - $correct, 'difference must trigger the refund');
    }
}
