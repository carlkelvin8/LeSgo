<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('registration_fee_payments')) {
            return;
        }

        Schema::create('registration_fee_payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('account_type', 20); // rider | merchant
            $table->decimal('amount', 10, 2);
            $table->string('currency', 10)->default('PHP');
            $table->string('paymongo_checkout_id')->nullable()->index();
            $table->string('paymongo_reference')->nullable()->unique();
            $table->string('idempotency_key')->unique();
            $table->string('checkout_url', 500)->nullable();
            $table->enum('payment_status', ['unpaid', 'pending', 'paid', 'waived', 'failed', 'expired'])->default('unpaid')->index();
            $table->timestamp('payment_date')->nullable();
            $table->timestamp('waived_at')->nullable();
            $table->foreignId('waived_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('waiver_reason')->nullable();
            $table->enum('application_status', ['pending', 'approved', 'rejected'])->default('pending')->index();
            $table->timestamp('approved_at')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('activated_at')->nullable();
            $table->boolean('is_active')->default(false)->index();
            $table->boolean('is_grandfathered')->default(false);
            $table->text('failure_reason')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'account_type'], 'uniq_reg_fee_user_type');
            $table->index(['account_type', 'payment_status']);
            $table->index(['account_type', 'application_status']);
        });

        // Seed configurable fee settings if not exist (do not overwrite existing)
        try {
            if (Schema::hasTable('security_settings')) {
                \App\Models\SecuritySetting::firstOrCreate(
                    ['setting_key' => 'registration.fee.rider'],
                    [
                        'setting_value' => '500.00',
                        'data_type' => 'string',
                        'description' => 'Rider registration fee amount (PHP)',
                        'category' => 'registration',
                        'is_sensitive' => false,
                        'requires_restart' => false,
                    ]
                );
                \App\Models\SecuritySetting::firstOrCreate(
                    ['setting_key' => 'registration.fee.merchant'],
                    [
                        'setting_value' => '1000.00',
                        'data_type' => 'string',
                        'description' => 'Merchant registration fee amount (PHP)',
                        'category' => 'registration',
                        'is_sensitive' => false,
                        'requires_restart' => false,
                    ]
                );
                \App\Models\SecuritySetting::firstOrCreate(
                    ['setting_key' => 'registration.fee.enforce_from'],
                    [
                        'setting_value' => now()->toDateString(),
                        'data_type' => 'string',
                        'description' => 'Enforce registration fee for users created on/after this date (grandfather earlier users)',
                        'category' => 'registration',
                        'is_sensitive' => false,
                        'requires_restart' => false,
                    ]
                );
            }
        } catch (\Throwable $e) {
            // Silently ignore if table not ready during migration dry-run
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('registration_fee_payments');
    }
};
