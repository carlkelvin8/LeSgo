<?php

namespace Tests\Feature;

use App\Models\ChatConversation;
use App\Models\DriverProfile;
use App\Models\Order;
use App\Models\User;
use App\Services\RealtimeService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Mockery;
use Tests\TestCase;

class ChatSafetyTest extends TestCase
{
    use RefreshDatabase;

    private User $customer;
    private User $driver;
    private ChatConversation $conversation;

    private function payAndApprove(User $user): void
    {
        // Riders must clear the registration-fee gate like real accounts.
        $fee = \App\Services\RegistrationFeeService::ensurePaymentRecord($user);
        $fee->update(['payment_status' => 'paid', 'payment_date' => now()]);
        \App\Services\RegistrationFeeService::approveApplication($fee->fresh(), User::factory()->create(['role' => 'admin']));
    }

    private function approvedDriver(): User
    {
        $driver = User::factory()->create(['role' => 'driver']);
        DriverProfile::factory()->create(['user_id' => $driver->id, 'status' => 'active']);
        $this->payAndApprove($driver);

        return $driver->fresh();
    }

    protected function setUp(): void
    {
        parent::setUp();

        $this->instance(RealtimeService::class, Mockery::mock(RealtimeService::class)->shouldIgnoreMissing());

        $this->customer = User::factory()->create(['role' => 'customer']);
        $this->driver = $this->approvedDriver();
        $order = Order::factory()->create(['customer_id' => $this->customer->id]);

        $this->conversation = ChatConversation::create([
            'order_id' => $order->id,
            'customer_id' => $this->customer->id,
            'driver_id' => $this->driver->id,
            'status' => 'active',
        ]);
    }

    public function test_driver_can_report_a_customer_message_and_it_creates_a_ticket(): void
    {
        $message = $this->conversation->messages()->create([
            'sender_id' => $this->customer->id,
            'sender_type' => 'customer',
            'message_type' => 'text',
            'content' => 'abusive text',
            'is_system_message' => false,
        ]);

        Sanctum::actingAs($this->driver);

        $this->postJson("/api/v1/chat/conversations/{$this->conversation->id}/report", [
            'reason' => 'harassment',
            'details' => 'Rude to me',
            'message_id' => $message->id,
        ])->assertCreated()
            ->assertJsonPath('data.blocked', false);

        $this->assertDatabaseHas('chat_reports', [
            'reporter_id' => $this->driver->id,
            'reported_user_id' => $this->customer->id,
            'message_id' => $message->id,
            'message_snapshot' => 'abusive text',
            'reason' => 'harassment',
        ]);
        $this->assertDatabaseHas('support_tickets', [
            'user_id' => $this->driver->id,
            'priority' => 'high',
            'subject' => 'Chat report: Harassment',
        ]);
    }

    public function test_user_cannot_report_their_own_message(): void
    {
        $message = $this->conversation->messages()->create([
            'sender_id' => $this->driver->id,
            'sender_type' => 'driver',
            'message_type' => 'text',
            'content' => 'mine',
            'is_system_message' => false,
        ]);

        Sanctum::actingAs($this->driver);

        $this->postJson("/api/v1/chat/conversations/{$this->conversation->id}/report", [
            'reason' => 'spam_or_scam',
            'message_id' => $message->id,
        ])->assertNotFound();
    }

    public function test_outsider_cannot_report_or_block(): void
    {
        Sanctum::actingAs($this->approvedDriver());

        $this->postJson("/api/v1/chat/conversations/{$this->conversation->id}/report", [
            'reason' => 'other',
        ])->assertNotFound();
        $this->postJson("/api/v1/chat/conversations/{$this->conversation->id}/block")->assertNotFound();
    }

    public function test_block_stops_both_sides_from_messaging_and_unblock_restores_it(): void
    {
        Sanctum::actingAs($this->driver);
        $this->postJson("/api/v1/chat/conversations/{$this->conversation->id}/block")
            ->assertOk()
            ->assertJsonPath('data.can_message', false);

        $this->postJson("/api/v1/chat/conversations/{$this->conversation->id}/messages", ['message' => 'hi'])
            ->assertForbidden();

        Sanctum::actingAs($this->customer);
        $this->postJson("/api/v1/chat/conversations/{$this->conversation->id}/messages", ['message' => 'hi'])
            ->assertForbidden();

        Sanctum::actingAs($this->driver);
        $this->deleteJson("/api/v1/chat/conversations/{$this->conversation->id}/block")
            ->assertOk()
            ->assertJsonPath('data.can_message', true);

        $this->postJson("/api/v1/chat/conversations/{$this->conversation->id}/messages", ['message' => 'hi'])
            ->assertCreated();
    }

    public function test_report_with_block_flag_blocks_the_user(): void
    {
        Sanctum::actingAs($this->customer);

        $this->postJson("/api/v1/chat/conversations/{$this->conversation->id}/report", [
            'reason' => 'threats_or_violence',
            'block' => true,
        ])->assertCreated()->assertJsonPath('data.blocked', true);

        $this->assertDatabaseHas('user_blocks', [
            'blocker_id' => $this->customer->id,
            'blocked_id' => $this->driver->id,
        ]);
    }

    public function test_profanity_is_masked_before_saving(): void
    {
        Sanctum::actingAs($this->customer);

        $this->postJson("/api/v1/chat/conversations/{$this->conversation->id}/messages", [
            'message' => 'Putangina mo, nasaan ka na? fuck',
        ])->assertCreated();

        $content = $this->conversation->messages()->latest('id')->value('content');
        $this->assertStringNotContainsStringIgnoringCase('putangina', $content);
        $this->assertStringNotContainsStringIgnoringCase('fuck', $content);
        $this->assertStringContainsString('nasaan ka na?', $content);
    }
}
