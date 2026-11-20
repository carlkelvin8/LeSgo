<?php

namespace Tests\Feature;

use App\Services\RiderCommissionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DriverPackageUpgradePriceTest extends TestCase
{
    use RefreshDatabase;

    public function test_upgrade_price_is_only_the_remaining_difference(): void
    {
        $this->assertSame(2000.0, RiderCommissionService::getUpgradePrice('basic', 'pro'));
        $this->assertSame(1000.0, RiderCommissionService::getUpgradePrice('basic', 'advance'));
        $this->assertSame(1000.0, RiderCommissionService::getUpgradePrice('advance', 'pro'));
    }

    public function test_catalog_exposes_upgrade_price_for_upgradeable_tiers_only(): void
    {
        $packages = collect(RiderCommissionService::packageCatalog('basic'))->keyBy('tier');

        $this->assertNull($packages['basic']['upgrade_price']  ?? null);
        $this->assertSame(1000.0, $packages['advance']['upgrade_price']);
        $this->assertSame(2000.0, $packages['pro']['upgrade_price']);

        $elite = collect(RiderCommissionService::packageCatalog('pro'))->keyBy('tier');
        $this->assertNull($elite['pro']['upgrade_price']);
    }
}
