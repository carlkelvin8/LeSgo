<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('merchant_withdrawal_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('wallet_id')->constrained('wallets')->cascadeOnDelete();
            $table->foreignId('partner_id')->nullable()->constrained('partners')->nullOnDelete();
            
            $table->decimal('amount', 12, 2);
            $table->decimal('fee', 12, 2)->default(0);
            $table->decimal('net_amount', 12, 2);
            $table->string('currency', 3)->default('PHP');
            
            $table->enum('status', [
                'pending',
                'processing',
                'completed',
                'rejected',
                'cancelled',
                'failed'
            ])->default('pending');
            
            $table->string('payout_method'); // 'gcash', 'maya', 'bank_transfer'
            $table->string('payout_account_name');
            $table->string('payout_account_number');
            $table->string('payout_bank_name')->nullable();
            
            $table->string('reference_number')->unique()->nullable();
            $table->string('external_transaction_id')->nullable();
            
            $table->text('rejection_reason')->nullable();
            $table->text('admin_notes')->nullable();
            
            $table->foreignId('processed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('processed_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            
            $table->timestamps();
            
            $table->index(['user_id', 'status']);
            $table->index(['partner_id', 'status']);
            $table->index('status');
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('merchant_withdrawal_requests');
    }
};
