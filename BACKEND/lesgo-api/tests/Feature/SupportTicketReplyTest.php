<?php

namespace Tests\Feature;

use App\Models\SupportTicket;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SupportTicketReplyTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_reply_without_sending_is_internal_field(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $ticket = SupportTicket::query()->create([
            'user_id' => $customer->id,
            'subject' => 'Need help',
            'description' => 'Original request',
            'category' => 'general_inquiry',
            'priority' => 'medium',
            'status' => 'waiting_customer',
        ]);

        Sanctum::actingAs($customer);

        $this->postJson("/api/v1/support/tickets/{$ticket->id}/messages", [
            'message' => 'Here is my reply.',
        ])->assertCreated()
            ->assertJsonPath('data.message', 'Here is my reply.')
            ->assertJsonPath('data.is_internal', false);

        $this->assertDatabaseHas('support_ticket_messages', [
            'ticket_id' => $ticket->id,
            'user_id' => $customer->id,
            'message' => 'Here is my reply.',
            'is_internal' => false,
        ]);
        $this->assertSame('open', $ticket->fresh()->status);
    }
}
