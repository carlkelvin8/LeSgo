<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Multi-branch merchants: each store order is fulfilled by one branch,
 * which supplies the pickup point.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('orders', 'partner_branch_id')) {
            return;
        }

        Schema::table('orders', function (Blueprint $table) {
            $table->foreignId('partner_branch_id')
                ->nullable()
                ->after('partner_id')
                ->constrained('partner_branches')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        if (! Schema::hasColumn('orders', 'partner_branch_id')) {
            return;
        }

        Schema::table('orders', function (Blueprint $table) {
            $table->dropConstrainedForeignId('partner_branch_id');
        });
    }
};
