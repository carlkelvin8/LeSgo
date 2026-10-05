<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public $withinTransaction = false;

    public function up(): void
    {
        // PGSQL: replace global unique constraint with partial unique where deleted_at IS NULL
        // so deleted users' emails can be reused. For MySQL, just drop unique and add normal index.
        $driver = DB::connection()->getDriverName();

        if ($driver === 'pgsql') {
            if (!\Illuminate\Support\Facades\Schema::hasColumn('users', 'deleted_at')) {
                return;
            }
            // Must drop UNIQUE CONSTRAINT, not just index. pgsql creates both.
            try {
                DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_unique');
            } catch (\Throwable $e) {}
            try {
                DB::statement('DROP INDEX IF EXISTS users_email_unique');
            } catch (\Throwable $e) {}
            try {
                DB::statement('DROP INDEX IF EXISTS users_email_unique_active');
            } catch (\Throwable $e) {}

            // If there are duplicate active emails, partial unique would fail and abort deploy.
            // Check first and fallback to non-unique index so deploy never breaks.
            $hasDuplicates = false;
            try {
                $dup = DB::select("SELECT email, COUNT(*) c FROM users WHERE deleted_at IS NULL GROUP BY email HAVING COUNT(*) > 1 LIMIT 1");
                $hasDuplicates = !empty($dup);
            } catch (\Throwable $e) {}

            if ($hasDuplicates) {
                \Illuminate\Support\Facades\Log::warning('Skipping partial unique index: duplicate active emails exist', ['count' => count($dup ?? [])]);
                try {
                    DB::statement('CREATE INDEX IF NOT EXISTS users_email_unique_active ON users (email) WHERE deleted_at IS NULL');
                } catch (\Throwable $inner) {}
                return;
            }

            // Create partial unique index: only active rows must have unique email
            try {
                DB::statement('CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique_active ON users (email) WHERE deleted_at IS NULL');
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning('Partial unique create failed, fallback to non-unique', ['error' => $e->getMessage()]);
                try {
                    DB::statement('CREATE INDEX IF NOT EXISTS users_email_unique_active ON users (email) WHERE deleted_at IS NULL');
                } catch (\Throwable $inner) {}
            }
        } else {
            // MySQL / others: unique constraint blocks reuse even with deleted_at column
            // Make email non-unique and rely on validation Rule::unique()->whereNull('deleted_at')
            try {
                Schema::table('users', function (Blueprint $table) {
                    $table->dropUnique(['email']);
                });
            } catch (\Throwable $e) {
                // maybe index name differs
                try {
                    DB::statement('DROP INDEX users_email_unique ON users');
                } catch (\Throwable $inner) {}
            }
            try {
                Schema::table('users', function (Blueprint $table) {
                    $table->index('email');
                });
            } catch (\Throwable $e) {}
        }
    }

    public function down(): void
    {
        $driver = DB::connection()->getDriverName();

        if ($driver === 'pgsql') {
            DB::statement('DROP INDEX IF EXISTS users_email_unique_active');
            // Recreate original global unique (will fail if duplicates exist)
            try {
                DB::statement('CREATE UNIQUE INDEX users_email_unique ON users (email)');
            } catch (\Throwable $e) {}
        } else {
            try {
                Schema::table('users', function (Blueprint $table) {
                    $table->dropIndex(['email']);
                });
            } catch (\Throwable $e) {}
            try {
                Schema::table('users', function (Blueprint $table) {
                    $table->unique('email');
                });
            } catch (\Throwable $e) {}
        }
    }
};
