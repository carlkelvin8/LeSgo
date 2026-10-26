<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * User-generated content safety (App Store Guideline 1.2): users can report
 * chat content and block the other participant.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_blocks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('blocker_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('blocked_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('conversation_id')->nullable()->constrained('chat_conversations')->nullOnDelete();
            $table->timestamps();

            $table->unique(['blocker_id', 'blocked_id']);
            $table->index('blocked_id');
        });

        Schema::create('chat_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reporter_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('reported_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('conversation_id')->nullable()->constrained('chat_conversations')->nullOnDelete();
            $table->foreignId('message_id')->nullable()->constrained('chat_messages')->nullOnDelete();
            $table->foreignId('support_ticket_id')->nullable()->constrained('support_tickets')->nullOnDelete();
            $table->string('reason', 50);
            $table->text('details')->nullable();
            $table->text('message_snapshot')->nullable();
            $table->string('status', 20)->default('pending');
            $table->timestamps();

            $table->index(['status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_reports');
        Schema::dropIfExists('user_blocks');
    }
};
