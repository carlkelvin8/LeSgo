<?php

namespace Tests\Feature;

use App\Events\ReadReceipt;
use App\Events\TypingIndicator;
use App\Models\ChatConversation;
use App\Models\ChatMessage;
use App\Models\DriverDutyAttendance;
use App\Models\DriverProfile;
use App\Models\Order;
use App\Models\Partner;
use App\Models\PartnerStaff;
use App\Models\Service;
use App\Models\User;
use App\Services\RealtimeService;
use App\Services\RegistrationFeeService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Mockery;
use Tests\TestCase;

/**
 * Launch fixes:
 *  1. Plain `throttle:N,M` route limits shared one counter per user, so
 *     hitting one throttled route (top-up) could 429 another (withdraw).
 *  2. Store owners/staff could send to an order's chat but got 404 reading it.
 *  3. The rider "attendance photo today" check used the UTC day, which rolls
 *     over at 08:00 in the Philippines.
 */
class LaunchFixesTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->instance(RealtimeService::class, Mockery::mock(RealtimeService::class)->shouldIgnoreMissing());
        Event::fake([TypingIndicator::class, ReadReceipt::class]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    // ── 1. Per-route throttle counters ────────────────────────────────────────

    public function test_exhausting_the_topup_limit_does_not_throttle_withdrawals(): void
    {
        $this->actingAsRole('customer');

        // Top-up allows 5/min. Empty bodies fail validation, but every hit counts.
        for ($i = 0; $i < 5; $i++) {
            $this->assertNotSame(429, $this->postJson('/api/v1/wallets/my/topup', [])->status());
        }
        $this->postJson('/api/v1/wallets/my/topup', [])->assertStatus(429);

        // Withdraw (3/min) has its own counter.
        $this->assertNotSame(429, $this->postJson('/api/v1/wallets/my/withdraw', [])->status());
    }

    public function test_exhausting_the_withdraw_limit_does_not_throttle_topups(): void
    {
        $this->actingAsRole('customer');

        for ($i = 0; $i < 3; $i++) {
            $this->assertNotSame(429, $this->postJson('/api/v1/wallets/my/withdraw', [])->status());
        }
        $this->postJson('/api/v1/wallets/my/withdraw', [])->assertStatus(429);

        $this->assertNotSame(429, $this->postJson('/api/v1/wallets/my/topup', [])->status());
    }

    // ── 2. Store users can read the order chat they write to ──────────────────

    private function store(): Partner
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);

        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'active', 'is_open' => true]);
        $fee = RegistrationFeeService::ensurePaymentRecord($owner);
        $fee->update(['payment_status' => 'waived', 'waived_at' => now(), 'application_status' => 'approved', 'is_active' => true]);

        return $partner;
    }

    /** @return array{0: Partner, 1: User, 2: int} */
    private function storeConversationWithCustomerReply(): array
    {
        $partner = $this->store();
        $customer = User::factory()->create(['role' => 'customer']);
        $order = Order::factory()->create([
            'partner_id' => $partner->id,
            'customer_id' => $customer->id,
            'service_id' => Service::factory()->create(['code' => 'LESEAT'])->id,
            'status' => 'pending',
        ]);

        $conversationId = $this->actingAs($partner->user, 'sanctum')
            ->getJson("/api/v1/chat/conversations/order/{$order->id}")
            ->assertOk()
            ->json('data.id');

        $this->actingAs($partner->user, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/messages", ['message' => 'Almost ready!'])
            ->assertCreated();

        $this->actingAs($customer, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/messages", ['message' => 'Thank you!'])
            ->assertCreated();

        return [$partner, $customer, $conversationId];
    }

    public function test_store_owner_reads_the_customers_reply_and_marks_it_read(): void
    {
        [$partner, , $conversationId] = $this->storeConversationWithCustomerReply();
        $owner = $partner->user;

        $this->actingAs($owner, 'sanctum')
            ->getJson('/api/v1/chat/unread-count')
            ->assertOk()
            ->assertJsonPath('data.count', 1);

        $this->actingAs($owner, 'sanctum')
            ->getJson('/api/v1/chat/conversations')
            ->assertOk()
            ->assertJsonPath('data.0.id', $conversationId)
            ->assertJsonPath('data.0.unread_count', 1);

        $this->actingAs($owner, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/typing", ['is_typing' => true])
            ->assertOk();

        $this->actingAs($owner, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/read")
            ->assertOk()
            ->assertJsonPath('data.marked_count', 1);

        $this->actingAs($owner, 'sanctum')
            ->getJson("/api/v1/chat/conversations/{$conversationId}/messages")
            ->assertOk()
            ->assertJsonPath('data.0.content', 'Thank you!')
            ->assertJsonPath('data.1.content', 'Almost ready!');

        $this->actingAs($owner, 'sanctum')
            ->getJson('/api/v1/chat/unread-count')
            ->assertJsonPath('data.count', 0);
    }

    public function test_store_staff_can_read_their_stores_order_thread(): void
    {
        [$partner, , $conversationId] = $this->storeConversationWithCustomerReply();

        $staff = User::factory()->create(['role' => 'partner_staff']);
        PartnerStaff::create(['partner_id' => $partner->id, 'user_id' => $staff->id, 'role' => 'cook', 'is_active' => true]);

        $this->actingAs($staff, 'sanctum')
            ->getJson("/api/v1/chat/conversations/{$conversationId}/messages")
            ->assertOk()
            ->assertJsonPath('data.0.content', 'Thank you!');
    }

    public function test_another_store_cannot_read_or_ack_the_thread(): void
    {
        [, , $conversationId] = $this->storeConversationWithCustomerReply();
        $other = $this->store();

        $this->actingAs($other->user, 'sanctum')
            ->getJson("/api/v1/chat/conversations/{$conversationId}/messages")
            ->assertNotFound();
        $this->actingAs($other->user, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/read")
            ->assertNotFound();
        $this->actingAs($other->user, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/typing", ['is_typing' => true])
            ->assertNotFound();
        $this->actingAs($other->user, 'sanctum')
            ->getJson('/api/v1/chat/conversations')
            ->assertOk()
            ->assertJsonCount(0, 'data');
        $this->actingAs($other->user, 'sanctum')
            ->getJson('/api/v1/chat/unread-count')
            ->assertJsonPath('data.count', 0);
    }

    public function test_customer_access_is_unchanged_and_strangers_still_get_404(): void
    {
        [, $customer, $conversationId] = $this->storeConversationWithCustomerReply();

        $this->actingAs($customer, 'sanctum')
            ->getJson("/api/v1/chat/conversations/{$conversationId}/messages")
            ->assertOk()
            ->assertJsonPath('data.1.content', 'Almost ready!');

        $stranger = User::factory()->create(['role' => 'customer']);
        $this->actingAs($stranger, 'sanctum')
            ->getJson("/api/v1/chat/conversations/{$conversationId}/messages")
            ->assertNotFound();
        $this->actingAs($stranger, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/read")
            ->assertNotFound();
    }

    /** Store thread with a rider on it; the customer has sent two messages. */
    private function storeConversationWithRider(): array
    {
        [$partner, $customer, $conversationId] = $this->storeConversationWithCustomerReply();
        $rider = $this->offDutyRider()->user;
        ChatConversation::whereKey($conversationId)->update(['driver_id' => $rider->id]);

        $this->actingAs($customer, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/messages", ['message' => 'Where are you?'])
            ->assertCreated();

        return [$partner, $customer, $rider, $conversationId];
    }

    private function unreadCountFor(User $user): int
    {
        return (int) $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/chat/unread-count')
            ->assertOk()
            ->json('data.count');
    }

    public function test_store_marking_read_does_not_mark_messages_read_for_the_rider(): void
    {
        [$partner, $customer, $rider, $conversationId] = $this->storeConversationWithRider();
        $owner = $partner->user;

        $riderUnread = $this->unreadCountFor($rider);
        $this->assertSame(3, $riderUnread); // store's message + 2 from the customer
        $this->assertSame(2, $this->unreadCountFor($owner)); // the store's own message does not count

        $this->actingAs($owner, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/read")
            ->assertOk()
            ->assertJsonPath('data.marked_count', 2);
        // Opening the thread must not touch read_at either.
        $this->actingAs($owner, 'sanctum')
            ->getJson("/api/v1/chat/conversations/{$conversationId}/messages")
            ->assertOk();

        $customerMessages = ChatMessage::where('conversation_id', $conversationId)
            ->where('sender_id', $customer->id)->get();
        $this->assertCount(2, $customerMessages);
        foreach ($customerMessages as $message) {
            $this->assertNull($message->read_at);
            $this->assertNotNull($message->store_read_at);
        }

        $this->assertSame(0, $this->unreadCountFor($owner));
        $this->assertSame($riderUnread, $this->unreadCountFor($rider));

        $this->actingAs($rider, 'sanctum')
            ->getJson('/api/v1/chat/conversations')
            ->assertJsonPath('data.0.unread_count', 3);
        $this->actingAs($owner, 'sanctum')
            ->getJson('/api/v1/chat/conversations')
            ->assertJsonPath('data.0.unread_count', 0);
    }

    public function test_rider_marking_read_does_not_change_the_stores_unread_count(): void
    {
        [$partner, , $rider, $conversationId] = $this->storeConversationWithRider();
        $owner = $partner->user;

        $this->actingAs($rider, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/messages", ['message' => 'On my way'])
            ->assertCreated();
        $this->assertSame(3, $this->unreadCountFor($owner)); // 2 customer + 1 rider

        $this->actingAs($rider, 'sanctum')
            ->postJson("/api/v1/chat/conversations/{$conversationId}/read")
            ->assertOk()
            ->assertJsonPath('data.marked_count', 3);
        $this->assertSame(0, $this->unreadCountFor($rider));

        $this->assertSame(3, $this->unreadCountFor($owner));
        $this->actingAs($owner, 'sanctum')
            ->getJson('/api/v1/chat/conversations')
            ->assertJsonPath('data.0.unread_count', 3);
    }

    // ── 3. Attendance "today" is the Philippine calendar day ──────────────────

    private function offDutyRider(): DriverProfile
    {
        $driver = User::factory()->create(['role' => 'driver']);
        $profile = DriverProfile::factory()->create([
            'user_id' => $driver->id,
            'status' => 'active',
            'is_available' => false,
        ]);

        $fee = RegistrationFeeService::ensurePaymentRecord($driver);
        $fee->update(['payment_status' => 'paid', 'payment_date' => now()]);
        RegistrationFeeService::approveApplication($fee->fresh(), User::factory()->create(['role' => 'admin']));

        return $profile;
    }

    private function attendanceAt(DriverProfile $profile, string $utc): void
    {
        DriverDutyAttendance::create([
            'driver_profile_id' => $profile->id,
            'user_id' => $profile->user_id,
            'photo_path' => 'attendance/test.jpg',
            'on_duty' => true,
            'captured_at' => Carbon::parse($utc, 'UTC'),
        ]);
    }

    public function test_attendance_photo_from_earlier_the_same_philippine_day_counts(): void
    {
        $profile = $this->offDutyRider();

        // Photo at 07:30 PHT on Nov 10 (still Nov 9 in UTC); going on duty at 09:00 PHT.
        $this->attendanceAt($profile, '2026-11-09 23:30:00');
        Carbon::setTestNow(Carbon::parse('2026-11-10 01:00:00', 'UTC'));

        $this->actingAs($profile->user, 'sanctum')
            ->patchJson("/api/v1/drivers/{$profile->id}", ['is_available' => true])
            ->assertOk();
        $this->assertTrue($profile->fresh()->is_available);
    }

    public function test_attendance_photo_from_the_previous_philippine_day_does_not_count(): void
    {
        $profile = $this->offDutyRider();

        // Photo at 23:00 PHT on Nov 10 (15:00 UTC); now 01:00 PHT on Nov 11 (same UTC day).
        $this->attendanceAt($profile, '2026-11-10 15:00:00');
        Carbon::setTestNow(Carbon::parse('2026-11-10 17:00:00', 'UTC'));

        $this->actingAs($profile->user, 'sanctum')
            ->patchJson("/api/v1/drivers/{$profile->id}", ['is_available' => true])
            ->assertStatus(422);
        $this->assertFalse($profile->fresh()->is_available);
    }
}
