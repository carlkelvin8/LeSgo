<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('services')) {
            return;
        }

        DB::table('services')
            ->where('code', 'LESRIDE')
            ->update([
                'name' => 'LesRide',
                'description' => 'Tricycle ride service',
                'base_fare' => 60.00,
                'per_km_rate' => 15.00,
                'minimum_fare' => 60.00,
                'is_active' => true,
                'updated_at' => now(),
            ]);
    }

    public function down(): void
    {
        // Do not disable a live service during rollback.
    }
};
