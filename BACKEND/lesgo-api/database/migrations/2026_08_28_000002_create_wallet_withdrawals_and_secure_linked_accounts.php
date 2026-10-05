<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('wallet_withdrawals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('wallet_id')->nullable()->constrained()->nullOnDelete();
            $table->decimal('amount', 12, 2);
            $table->string('currency', 3)->default('PHP');
            $table->string('status', 32)->default('processing');
            $table->string('provider', 20);
            $table->string('withdrawal_method', 20);
            $table->string('external_reference')->unique();
            $table->string('gateway_reference')->nullable()->index();
            $table->string('account_last4', 4)->nullable();
            $table->text('failure_reason')->nullable();
            $table->timestamp('debited_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('failed_at')->nullable();
            $table->timestamp('reversed_at')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->unique(['provider', 'gateway_reference']);
        });

        Schema::create('payment_refunds', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payment_id')->constrained()->cascadeOnDelete();
            $table->foreignId('requested_by')->nullable()->constrained('users')->nullOnDelete();
            $table->decimal('amount', 12, 2);
            $table->string('currency', 3)->default('PHP');
            $table->string('provider', 20);
            $table->string('payment_reference');
            $table->uuid('idempotency_key')->unique();
            $table->string('gateway_reference')->nullable()->index();
            $table->string('status', 32)->default('processing');
            $table->string('reason', 64)->nullable();
            $table->text('failure_reason')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index(['payment_id', 'status']);
        });

        Schema::table('wallet_linked_accounts', function (Blueprint $table) {
            $table->text('account_details_encrypted')->nullable();
        });

        DB::table('wallet_linked_accounts')
            ->orderBy('id')
            ->chunkById(100, function ($accounts) {
                foreach ($accounts as $account) {
                    $meta = is_string($account->meta)
                        ? json_decode($account->meta, true)
                        : (array) $account->meta;
                    $details = array_filter([
                        'account_number' => $meta['account_number'] ?? null,
                        'account_holder_name' => $meta['account_holder_name'] ?? null,
                    ]);

                    if ($details === []) {
                        continue;
                    }

                    unset($meta['account_number'], $meta['account_holder_name']);
                    DB::table('wallet_linked_accounts')
                        ->where('id', $account->id)
                        ->update([
                            'account_details_encrypted' => Crypt::encryptString(json_encode($details, JSON_THROW_ON_ERROR)),
                            'meta' => json_encode($meta, JSON_THROW_ON_ERROR),
                        ]);
                }
            });
    }

    public function down(): void
    {
        Schema::table('wallet_linked_accounts', function (Blueprint $table) {
            $table->dropColumn('account_details_encrypted');
        });

        Schema::dropIfExists('payment_refunds');
        Schema::dropIfExists('wallet_withdrawals');
    }
};
