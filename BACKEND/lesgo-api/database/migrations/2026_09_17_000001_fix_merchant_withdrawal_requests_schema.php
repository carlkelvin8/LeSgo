<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Repair columns that the MerchantWithdrawalRequest model expects but the
     * original create migration never added: the approval audit columns and the
     * soft-delete timestamp (`$table->softDeletes()`).
     */
    public function up(): void
    {
        Schema::table('merchant_withdrawal_requests', function (Blueprint $table) {
            if (! Schema::hasColumn('merchant_withdrawal_requests', 'approved_by')) {
                $table->foreignId('approved_by')
                    ->nullable()
                    ->after('admin_notes')
                    ->constrained('users')
                    ->nullOnDelete();
            }

            if (! Schema::hasColumn('merchant_withdrawal_requests', 'approved_at')) {
                $table->timestamp('approved_at')->nullable()->after('approved_by');
            }

            if (! Schema::hasColumn('merchant_withdrawal_requests', 'deleted_at')) {
                $table->softDeletes();
            }
        });
    }

    public function down(): void
    {
        Schema::table('merchant_withdrawal_requests', function (Blueprint $table) {
            if (Schema::hasColumn('merchant_withdrawal_requests', 'approved_by')) {
                $table->dropConstrainedForeignId('approved_by');
            }

            if (Schema::hasColumn('merchant_withdrawal_requests', 'approved_at')) {
                $table->dropColumn('approved_at');
            }

            if (Schema::hasColumn('merchant_withdrawal_requests', 'deleted_at')) {
                $table->dropSoftDeletes();
            }
        });
    }
};
