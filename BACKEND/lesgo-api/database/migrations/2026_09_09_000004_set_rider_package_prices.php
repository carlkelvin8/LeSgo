<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    private const PRICES = [
        'rider.package.price.basic' => '999.00',
        'rider.package.price.advance' => '1999.00',
        'rider.package.price.pro' => '2999.00',
    ];

    public function up(): void
    {
        if (!Schema::hasTable('security_settings')) {
            return;
        }

        foreach (self::PRICES as $key => $price) {
            DB::table('security_settings')->updateOrInsert(
                ['setting_key' => $key],
                [
                    'setting_value' => $price,
                    'data_type' => 'string',
                    'description' => 'One-time rider package registration price in PHP',
                    'category' => 'rider_packages',
                    'is_sensitive' => false,
                    'requires_restart' => false,
                    'updated_at' => now(),
                    'created_at' => now(),
                ],
            );
        }
    }

    public function down(): void
    {
        if (!Schema::hasTable('security_settings')) {
            return;
        }

        $legacyPrices = [
            'rider.package.price.basic' => '999.00',
            'rider.package.price.advance' => '2499.00',
            'rider.package.price.pro' => '3499.00',
        ];

        foreach ($legacyPrices as $key => $price) {
            DB::table('security_settings')
                ->where('setting_key', $key)
                ->update(['setting_value' => $price, 'updated_at' => now()]);
        }
    }
};
