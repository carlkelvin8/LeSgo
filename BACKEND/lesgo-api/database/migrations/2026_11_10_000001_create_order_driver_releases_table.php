<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Riders who backed out of an order before pickup. The order goes back to
     * the pool, but never to the rider who left it (no re-offer, no auto-assign).
     */
    public function up(): void
    {
        if (Schema::hasTable('order_driver_releases')) {
            return;
        }

        Schema::create('order_driver_releases', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
            $table->unsignedBigInteger('driver_profile_id');
            $table->string('reason', 500)->nullable();
            $table->timestamps();

            $table->unique(['order_id', 'driver_profile_id']);
            $table->index('driver_profile_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_driver_releases');
    }
};
