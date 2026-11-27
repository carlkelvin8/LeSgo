<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('orders', 'ready_for_pickup_at')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->timestamp('ready_for_pickup_at')->nullable()->after('accepted_at');
            });
        }

        // Preserve the ready signal for orders created before this field existed.
        DB::table('orders')
            ->where('status', 'ready_for_pickup')
            ->whereNull('ready_for_pickup_at')
            ->update(['ready_for_pickup_at' => DB::raw('updated_at')]);
    }

    public function down(): void
    {
        if (Schema::hasColumn('orders', 'ready_for_pickup_at')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->dropColumn('ready_for_pickup_at');
            });
        }
    }
};
