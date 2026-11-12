<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * The store's quick replies (merchant app) message the customer while the
     * order is still being prepared, i.e. usually before any rider is assigned,
     * and the sender is a store user, not a customer/driver.
     *
     *  - chat_conversations.driver_id was NOT NULL, although ChatController
     *    already creates conversations with a null rider and fills it in later.
     *  - chat_messages.sender_type was an enum of customer|driver|system, so a
     *    partner_admin/partner_staff message violated the constraint.
     */
    public function up(): void
    {
        Schema::table('chat_conversations', function (Blueprint $table) {
            $table->unsignedBigInteger('driver_id')->nullable()->change();
        });

        if (DB::getDriverName() === 'pgsql') {
            // Laravel's enum() on PostgreSQL is varchar + a CHECK constraint.
            DB::statement('ALTER TABLE chat_messages DROP CONSTRAINT IF EXISTS chat_messages_sender_type_check');
        } else {
            Schema::table('chat_messages', function (Blueprint $table) {
                $table->string('sender_type', 32)->change();
            });
        }
    }

    public function down(): void
    {
        // Rows with a null rider / store sender may exist: not reversible.
    }
};
