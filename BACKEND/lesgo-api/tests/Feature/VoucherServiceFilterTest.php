<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class VoucherServiceFilterTest extends TestCase
{
    use RefreshDatabase;

    private function codes(?int $serviceId): array
    {
        $this->actingAsRole('customer');
        $url = '/api/v1/vouchers/available'.($serviceId === null ? '' : '?service_id='.$serviceId);

        return collect($this->getJson($url)->assertOk()->json('data'))->pluck('code')->all();
    }

    public function test_without_a_service_every_voucher_is_listed(): void
    {
        $codes = $this->codes(null);

        foreach (['SAVE20', 'FREEDEL', 'RIDE20', 'LUNCHFREE'] as $code) {
            $this->assertContains($code, $codes);
        }
    }

    public function test_a_food_order_only_lists_vouchers_that_work_for_lesEat(): void
    {
        $codes = $this->codes(3);

        $this->assertContains('LUNCHFREE', $codes, 'LesEat-only voucher');
        $this->assertContains('SAVE20', $codes, 'no service restriction means every service');
        $this->assertNotContains('FREEDEL', $codes, 'LesGo/LesRide only');
        $this->assertNotContains('RIDE20', $codes, 'LesRide only');
    }

    public function test_a_ride_lists_ride_vouchers_but_not_food_only_ones(): void
    {
        $codes = $this->codes(2);

        $this->assertContains('RIDE20', $codes);
        $this->assertContains('FREEDEL', $codes);
        $this->assertNotContains('LUNCHFREE', $codes);
    }
}
