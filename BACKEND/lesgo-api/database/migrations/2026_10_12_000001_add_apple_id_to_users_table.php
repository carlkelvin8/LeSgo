<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'apple_id')) {
                $table->string('apple_id')->nullable()->unique();
            }
        });
    }

    public function down(): void
    {
        if (! Schema::hasColumn('users', 'apple_id')) {
            return;
        }

        // Drop the unique index first; SQLite cannot drop an indexed column.
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['apple_id']);
        });
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('apple_id');
        });
    }
};
