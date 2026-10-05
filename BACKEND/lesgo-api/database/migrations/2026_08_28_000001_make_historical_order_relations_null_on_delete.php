<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['driver_id']);
            $table->dropForeign(['pickup_address_id']);
            $table->dropForeign(['dropoff_address_id']);

            $table->foreign('driver_id')
                ->references('id')
                ->on('driver_profiles')
                ->nullOnDelete();
            $table->foreign('pickup_address_id')
                ->references('id')
                ->on('addresses')
                ->nullOnDelete();
            $table->foreign('dropoff_address_id')
                ->references('id')
                ->on('addresses')
                ->nullOnDelete();
        });

        Schema::table('payments', function (Blueprint $table) {
            $table->dropForeign(['driver_id']);
            $table->foreign('driver_id')
                ->references('id')
                ->on('driver_profiles')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropForeign(['driver_id']);
            $table->foreign('driver_id')
                ->references('id')
                ->on('driver_profiles');
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['driver_id']);
            $table->dropForeign(['pickup_address_id']);
            $table->dropForeign(['dropoff_address_id']);

            $table->foreign('driver_id')
                ->references('id')
                ->on('driver_profiles');
            $table->foreign('pickup_address_id')
                ->references('id')
                ->on('addresses');
            $table->foreign('dropoff_address_id')
                ->references('id')
                ->on('addresses');
        });
    }
};
