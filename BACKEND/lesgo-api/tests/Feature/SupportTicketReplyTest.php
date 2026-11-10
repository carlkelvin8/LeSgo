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

    public function test_rider_app_ticket_with_legacy_general_category_is_actually_stored(): void
    {
        $rider = User::factory()->create(['role' => 'customer']);
        Sanctum::actingAs($rider);

        $this->postJson('/api/v1/support/tickets', [
            'subject' => 'Rider support chat',
            'description' => 'I need help with my earnings',
            'category' => 'general',
            'priority' => 'medium',
        ])->assertCreated()
            ->assertJsonPath('data.status', 'open');

        $this->assertDatabaseHas('support_tickets', [
            'user_id' => $rider->id,
            'description' => 'I need help with my earnings',
            'category' => 'general_inquiry',
        ]);
        $this->assertDatabaseHas('support_ticket_messages', [
            'user_id' => $rider->id,
            'message' => 'I need help with my earnings',
        ]);
    }

    public function test_unknown_ticket_category_is_rejected_instead_of_faking_success(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'customer']));

        $this->postJson('/api/v1/support/tickets', [
            'subject' => 'x',
            'description' => 'y',
            'category' => 'definitely-not-a-category',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('category');

        $this->assertDatabaseCount('support_tickets', 0);
    }
}
