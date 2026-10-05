<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('registration_fee_payments')) {
            return;
        }

        // Use a new migration so installations that ran the original table
        // migration before waiver support was added can be repaired safely.
        if (!Schema::hasColumn('registration_fee_payments', 'waived_at')) {
            Schema::table('registration_fee_payments', function (Blueprint $table) {
                $table->timestamp('waived_at')->nullable()->after('payment_date');
            });
        }

        if (!Schema::hasColumn('registration_fee_payments', 'waived_by')) {
            Schema::table('registration_fee_payments', function (Blueprint $table) {
                $table->foreignId('waived_by')->nullable()->after('waived_at')->constrained('users')->nullOnDelete();
            });
        }

        if (!Schema::hasColumn('registration_fee_payments', 'waiver_reason')) {
            Schema::table('registration_fee_payments', function (Blueprint $table) {
                $table->text('waiver_reason')->nullable()->after('waived_by');
            });
        }

        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE registration_fee_payments MODIFY payment_status ENUM('unpaid','pending','paid','waived','failed','expired') NOT NULL DEFAULT 'unpaid'");
        }
    }

    public function down(): void
    {
        // Keep existing waiver records and their audit fields intact.
    }
};
