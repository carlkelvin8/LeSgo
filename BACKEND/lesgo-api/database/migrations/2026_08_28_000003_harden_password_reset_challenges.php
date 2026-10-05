<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('password_resets', function (Blueprint $table) {
            $table->string('otp_hash')->nullable()->after('otp');
            $table->unsignedTinyInteger('verification_attempts')->default(0)->after('otp_hash');
            $table->timestamp('verified_at')->nullable()->after('verification_attempts');
            $table->string('reset_token_hash')->nullable()->after('reset_token');
            $table->timestamp('reset_token_expires_at')->nullable()->after('reset_token_hash');
        });

        // Legacy rows contain plaintext credentials and cannot be safely upgraded.
        DB::table('password_resets')
            ->where('is_used', false)
            ->update([
                'is_used' => true,
                'used_at' => now(),
            ]);
    }

    public function down(): void
    {
        Schema::table('password_resets', function (Blueprint $table) {
            $table->dropColumn([
                'otp_hash',
                'verification_attempts',
                'verified_at',
                'reset_token_hash',
                'reset_token_expires_at',
            ]);
        });
    }
};
