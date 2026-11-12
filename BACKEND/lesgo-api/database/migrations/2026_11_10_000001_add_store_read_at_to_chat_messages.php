<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * The store (owner/staff) reads the same order thread as the customer and
     * rider. read_at is shared by the customer and rider, so the store keeps its
     * own read marker: a store reading the thread must not make the customer's
     * messages look read to the rider.
     */
    public function up(): void
    {
        if (! Schema::hasColumn('chat_messages', 'store_read_at')) {
            Schema::table('chat_messages', function (Blueprint $table) {
                $table->timestamp('store_read_at')->nullable();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('chat_messages', 'store_read_at')) {
            Schema::table('chat_messages', function (Blueprint $table) {
                $table->dropColumn('store_read_at');
            });
        }
    }
};
