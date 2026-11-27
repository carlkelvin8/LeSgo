<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Partner;
use App\Models\PartnerStaff;
use App\Models\Service;
use App\Models\User;
use App\Services\RealtimeService;
use App\Services\RegistrationFeeService;
use Mockery;
use Tests\TestCase;

/**
 * The merchant app's "Quick Reply" chips message the customer of an order. The
 * chat API only knew customers and riders, so every quick reply failed with a
 * 403/404 ("Failed to send message").
 */
class MerchantQuickReplyChatTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        $this->instance(RealtimeService::class, Mockery::mock(RealtimeService::class)->shouldIgnoreMissing());
    }

    private function store(): Partner
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);

        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'active', 'is_open' => true]);
        $fee = RegistrationFeeService::ensurePaymentRecord($owner);
        $fee->update(['payment_status' => 'waived', 'waived_at' => now(), 'application_status' => 'approved', 'is_active' => true]);

        return $partner;
    }

    private function orderFor(Partner $partner, ?User $customer = null): Order
    {
        return Order::factory()->create([
            'partner_id' => $partner->id,
            'customer_id' => ($customer ?? User::factory()->create(['role' => 'customer']))->id,
            'service_id' => Service::factory()->create(['code' => 'LESEAT'])->id,
            'status' => 'pending',
        ]);
    }

    public function test_store_owner_can_open_the_conversation_and_message_the_customer(): void
    {
        $partner = $this->store();
        $customer = User::factory()->create(['role' => 'customer']);
        $order = $this->orderFor($partner, $customer);

        $conversationId = $this->actingAs($partner->user, 'sanctum')
            ->getJson("/api/v1/chat/conversations/order/{$order->id}")
            ->assertOk()
            ->json('data.id');

        $this->actingAs($partner->user, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/messages", ['message' => 'Almost ready!'])
            ->assertCreated()
            ->assertJsonPath('data.content', 'Almost ready!');

        $this->actingAs($customer, 'sanctum')
            ->getJson("/api/v1/chat/conversations/{$conversationId}/messages")
            ->assertOk()
            ->assertJsonPath('data.0.content', 'Almost ready!')
            ->assertJsonPath('data.0.sender_type', 'partner_admin');

        $this->actingAs($customer, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/messages", ['message' => 'Thanks'])
            ->assertCreated();
    }

    public function test_store_staff_can_message_but_other_stores_cannot(): void
    {
        $partner = $this->store();
        $order = $this->orderFor($partner);

        $staff = User::factory()->create(['role' => 'partner_staff']);
        PartnerStaff::create(['partner_id' => $partner->id, 'user_id' => $staff->id, 'role' => 'cook', 'is_active' => true]);

        $conversationId = $this->actingAs($staff, 'sanctum')
            ->getJson("/api/v1/chat/conversations/order/{$order->id}")
            ->assertOk()
            ->json('data.id');
        $this->actingAs($staff, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/messages", ['message' => 'Hello'])
            ->assertCreated();

        $other = $this->store();
        $this->actingAs($other->user, 'sanctum')
            ->getJson("/api/v1/chat/conversations/order/{$order->id}")
            ->assertForbidden();
        $this->actingAs($other->user, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/messages", ['message' => 'Hello'])
            ->assertNotFound();
    }

    public function test_store_reads_its_own_orders_thread_but_not_other_stores(): void
    {
        // The store writes to the order's thread, so it must be able to read the
        // replies there; other stores still cannot.
        $partner = $this->store();
        $order = $this->orderFor($partner);

        $conversationId = $this->actingAs($partner->user, 'sanctum')
            ->getJson("/api/v1/chat/conversations/order/{$order->id}")
            ->json('data.id');

        $this->actingAs($partner->user, 'sanctum')
            ->getJson("/api/v1/chat/conversations/{$conversationId}/messages")
            ->assertOk();

        $this->actingAs($this->store()->user, 'sanctum')
            ->getJson("/api/v1/chat/conversations/{$conversationId}/messages")
            ->assertNotFound();
    }
}
