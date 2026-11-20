<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Fixed test merchant + rider used by the emulator automation
 * (scripts/e2e-emulator.sh -> RIDERSIDE/integration_test).
 *
 *   merchant@test.com     / Password123!
 *   testrider@lesgo.com   / TestRider123!
 *
 * Idempotent. Run: php artisan db:seed --class=E2ETestAccountsSeeder
 */
class E2ETestAccountsSeeder extends Seeder
{
    public function run(): void
    {
        $this->call(TestMerchantSeeder::class);

        User::whereIn('email', ['merchant@test.com', 'testrider@lesgo.com'])
            ->whereNull('email_verified_at')
            ->update(['email_verified_at' => now()]);
    }
}
