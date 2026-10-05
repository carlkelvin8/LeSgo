<?php

namespace Tests\Feature;

use App\Jobs\DeleteMediaObjectsJob;
use App\Models\Address;
use App\Models\ChatConversation;
use App\Models\ChatMessage;
use App\Models\DocumentVerification;
use App\Models\DriverProfile;
use App\Models\Order;
use App\Models\OrderTrackingEvent;
use App\Models\Payment;
use App\Models\User;
use App\Models\Vehicle;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class AccountDeletionAndGoogleAuthTest extends TestCase
{
    private const GOOGLE_CLIENT_ID = 'test-client.apps.googleusercontent.com';

    public function test_google_customer_can_deactivate_without_a_password(): void
    {
        $user = User::factory()->create(['google_id' => 'google-deactivate']);
        $this->fakeGoogleIdentity($user);
        $this->withToken($this->tokenFor($user))->postJson('/api/v1/auth/account/deactivate', [
            'google_id_token' => 'valid-token',
        ])->assertOk();
        $this->assertFalse($user->fresh()->is_active);
        $this->assertSame(0, $user->tokens()->count());
    }

    public function test_wrong_google_identity_cannot_deactivate_or_delete_an_account(): void
    {
        $user = User::factory()->create(['google_id' => 'original-subject']);
        $other = User::factory()->make(['email' => $user->email, 'google_id' => 'other-subject']);
        $this->fakeGoogleIdentity($other);
        foreach (['deactivate', 'delete'] as $action) {
            $this->withToken($this->tokenFor($user))->postJson('/api/v1/auth/account/'.$action, [
                'google_id_token' => 'wrong-token', 'confirmation' => 'DELETE',
            ])->assertUnprocessable();
        }
        $this->assertTrue($user->fresh()->is_active);
        $this->assertNull($user->fresh()->deleted_at);
    }

    public function test_google_token_with_wrong_audience_cannot_login_or_delete(): void
    {
        $user = User::factory()->create(['google_id' => 'original-subject']);
        Http::fake(['oauth2.googleapis.com/tokeninfo*' => Http::response([
            'aud' => 'another-app', 'sub' => $user->google_id,
            'email' => $user->email, 'email_verified' => 'true',
        ])]);
        $this->postJson('/api/v1/auth/google', ['id_token' => 'wrong-audience'])->assertUnauthorized();
        $this->withToken($this->tokenFor($user))->postJson('/api/v1/auth/account/delete', [
            'google_id_token' => 'wrong-audience', 'confirmation' => 'DELETE',
        ])->assertUnprocessable();
        $this->assertNull($user->fresh()->deleted_at);
    }

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.google.client_id' => self::GOOGLE_CLIENT_ID]);
    }

    public function test_inactive_google_account_returns_forbidden_without_type_error(): void
    {
        $user = User::factory()->create([
            'email' => 'inactive@example.com',
            'google_id' => 'google-subject-1',
            'is_active' => false,
        ]);
        $this->fakeGoogleIdentity($user);

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'valid-google-token',
        ])->assertForbidden()
            ->assertJsonPath('success', false)
            ->assertJsonPath(
                'message',
                'Your account has been deactivated. Please contact support.'
            );

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_google_login_rejects_a_different_subject_for_a_linked_email(): void
    {
        $user = User::factory()->create([
            'email' => 'linked@example.com',
            'google_id' => 'original-google-subject',
        ]);
        $otherIdentity = User::factory()->make([
            'email' => $user->email,
            'google_id' => 'different-google-subject',
        ]);
        $this->fakeGoogleIdentity($otherIdentity);

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'different-google-token',
        ])->assertUnauthorized()
            ->assertJsonPath(
                'message',
                'This Google identity does not match the linked account.'
            );

        $this->assertSame('original-google-subject', $user->fresh()->google_id);
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_new_google_customer_is_sent_to_identity_onboarding(): void
    {
        $identity = User::factory()->make([
            'name' => 'New Google Customer',
            'email' => 'new-google@example.com',
            'google_id' => 'new-google-subject',
        ]);
        $this->fakeGoogleIdentity($identity);

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'valid-google-token',
        ])->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('is_new_user', true)
            ->assertJsonPath('requires_identity_verification', true);
    }

    public function test_google_customer_with_submitted_id_does_not_repeat_onboarding(): void
    {
        $user = User::factory()->create([
            'email' => 'verified-google@example.com',
            'google_id' => 'verified-google-subject',
        ]);
        DocumentVerification::create([
            'user_id' => $user->id,
            'document_type' => 'valid_id',
            'document_number' => 'P1234567',
            'document_urls' => ['https://media.example.test/id-front.jpg'],
            'status' => 'pending',
            'submitted_at' => now(),
        ]);
        $this->fakeGoogleIdentity($user);

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'valid-google-token',
        ])->assertOk()
            ->assertJsonPath('requires_identity_verification', false);
    }

    public function test_google_only_customer_can_verify_and_delete_account(): void
    {
        $user = User::factory()->create([
            'email' => 'google-only@example.com',
            'google_id' => 'google-subject-2',
            'password' => Hash::make(str()->random(64)),
        ]);
        $this->fakeGoogleIdentity($user);

        $this->withToken($this->tokenFor($user))
            ->postJson('/api/v1/auth/account/delete', [
                'google_id_token' => 'valid-google-token',
                'confirmation' => 'DELETE',
            ])->assertOk()
            ->assertJsonPath('success', true);

        $user->refresh();
        $this->assertNull($user->google_id);
        $this->assertFalse($user->is_active);
        $this->assertStringEndsWith('@deleted.local', $user->email);
    }

    public function test_google_credential_for_another_account_cannot_delete_user(): void
    {
        $user = User::factory()->create([
            'email' => 'owner@example.com',
            'google_id' => 'owner-subject',
        ]);
        $other = User::factory()->make([
            'email' => 'other@example.com',
            'google_id' => 'other-subject',
        ]);
        $this->fakeGoogleIdentity($other);

        $this->withToken($this->tokenFor($user))
            ->postJson('/api/v1/auth/account/delete', [
                'google_id_token' => 'other-google-token',
                'confirmation' => 'DELETE',
            ])->assertUnprocessable()
            ->assertJsonPath('message', 'Account verification failed.');

        $this->assertTrue($user->fresh()->is_active);
        $this->assertSame('owner@example.com', $user->fresh()->email);
    }

    public function test_customer_deletion_redacts_historical_orders_and_chat_atomically(): void
    {
        Queue::fake();
        $customer = User::factory()->create([
            'password' => Hash::make('Secret123'),
            'profile_photo_url' => 'profiles/customer.jpg',
        ]);
        $driver = User::factory()->driver()->create();
        $pickup = Address::create($this->addressPayload($customer, 'Pickup'));
        $dropoff = Address::create($this->addressPayload($customer, 'Dropoff'));
        $order = Order::factory()->completed()->create([
            'customer_id' => $customer->id,
            'pickup_address_id' => $pickup->id,
            'dropoff_address_id' => $dropoff->id,
            'pickup_address' => 'Private pickup address',
            'pickup_contact_name' => 'Private Customer',
            'pickup_contact_phone' => '09171234567',
            'dropoff_address' => 'Private destination',
            'dropoff_contact_name' => 'Recipient Name',
            'dropoff_contact_phone' => '09991234567',
            'notes' => 'Gate code 1234',
            'proof_images' => ['proofs/delivery.jpg'],
            'meta' => [
                'customer_email' => $customer->email,
                'pricing_version' => 'v2',
            ],
        ]);
        Payment::factory()->paid()->create([
            'order_id' => $order->id,
            'customer_id' => $customer->id,
            'meta' => ['payer_email' => $customer->email, 'gateway' => 'xendit'],
        ]);
        OrderTrackingEvent::createEvent(
            $order,
            'delivered',
            'Delivered',
            'Delivered to Private Customer',
            $customer,
            [
                'latitude' => 8.45,
                'longitude' => 124.63,
                'location_address' => 'Private destination',
                'attachments' => ['tracking/dropoff.jpg'],
            ]
        );
        $conversation = ChatConversation::create([
            'order_id' => $order->id,
            'customer_id' => $customer->id,
            'driver_id' => $driver->id,
        ]);
        ChatMessage::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $driver->id,
            'sender_type' => 'driver',
            'content' => 'I am outside your gate.',
        ]);

        $this->withToken($this->tokenFor($customer))
            ->postJson('/api/v1/auth/account/delete', [
                'password' => 'Secret123',
                'confirmation' => 'DELETE',
            ])->assertOk();

        $redactedOrder = $order->fresh();
        $this->assertNull($redactedOrder->pickup_address_id);
        $this->assertNull($redactedOrder->dropoff_address_id);
        $this->assertNull($redactedOrder->pickup_address);
        $this->assertNull($redactedOrder->pickup_contact_phone);
        $this->assertSame(['pricing_version' => 'v2'], $redactedOrder->meta);
        $this->assertDatabaseMissing('addresses', ['user_id' => $customer->id]);
        $this->assertDatabaseMissing('chat_conversations', ['id' => $conversation->id]);
        $this->assertDatabaseMissing('chat_messages', ['conversation_id' => $conversation->id]);
        $this->assertDatabaseHas('payments', [
            'order_id' => $order->id,
            'customer_id' => $customer->id,
        ]);
        $this->assertDatabaseHas('order_tracking_events', [
            'order_id' => $order->id,
            'user_id' => null,
            'event_description' => null,
            'location_address' => null,
        ]);

        Queue::assertPushed(DeleteMediaObjectsJob::class, function ($job) {
            return in_array('profiles/customer.jpg', $job->paths, true)
                && in_array('proofs/delivery.jpg', $job->paths, true)
                && in_array('tracking/dropoff.jpg', $job->paths, true);
        });
    }

    public function test_driver_deletion_keeps_financial_history_but_erases_profile_data(): void
    {
        Queue::fake();
        $driver = User::factory()->driver()->create([
            'password' => Hash::make('Secret123'),
        ]);
        $profile = DriverProfile::factory()->create([
            'user_id' => $driver->id,
            'status' => 'active',
            'license_number' => 'PRIVATE-LICENSE',
            'id_document_path' => 'drivers/id.jpg',
            'documents' => ['drivers/license.jpg'],
        ]);
        Vehicle::create([
            'driver_id' => $profile->id,
            'type' => 'tricycle',
            'plate_number' => 'ABC 1234',
            'status' => 'active',
        ]);
        $order = Order::factory()->completed()->create(['driver_id' => $profile->id]);
        $payment = Payment::factory()->paid()->create([
            'order_id' => $order->id,
            'customer_id' => $order->customer_id,
            'driver_id' => $profile->id,
            'meta' => ['driver_phone' => $driver->phone_number, 'gateway' => 'cash'],
        ]);
        DB::table('driver_duty_attendances')->insert([
            'driver_profile_id' => $profile->id,
            'user_id' => $driver->id,
            'photo_path' => 'drivers/duty.jpg',
            'on_duty' => false,
            'captured_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->withToken($this->tokenFor($driver))
            ->postJson('/api/v1/auth/account/delete', [
                'password' => 'Secret123',
                'confirmation' => 'DELETE',
            ])->assertOk();

        $profile->refresh();
        $this->assertSame('deleted', $profile->status);
        $this->assertNull($profile->license_number);
        $this->assertNull($profile->id_document_path);
        $this->assertNull($profile->documents);
        $this->assertSame($profile->id, $order->fresh()->driver_id);
        $this->assertSame($profile->id, $payment->fresh()->driver_id);
        $this->assertDatabaseMissing('vehicles', ['driver_id' => $profile->id]);
        $this->assertDatabaseMissing('driver_duty_attendances', ['user_id' => $driver->id]);

        Queue::assertPushed(DeleteMediaObjectsJob::class, function ($job) {
            return in_array('drivers/id.jpg', $job->paths, true)
                && in_array('drivers/license.jpg', $job->paths, true)
                && in_array('drivers/duty.jpg', $job->paths, true);
        });
    }

    private function fakeGoogleIdentity(User $user): void
    {
        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response([
                'aud' => self::GOOGLE_CLIENT_ID,
                'sub' => $user->google_id,
                'email' => $user->email,
                'email_verified' => 'true',
            ]),
        ]);
    }

    /** @return array<string, mixed> */
    private function addressPayload(User $user, string $label): array
    {
        return [
            'user_id' => $user->id,
            'label' => $label,
            'contact_name' => $user->name,
            'contact_phone' => $user->phone_number,
            'address_line1' => "{$label} private address",
            'city' => 'Claveria',
            'region' => 'Misamis Oriental',
            'country' => 'Philippines',
            'latitude' => 8.61,
            'longitude' => 124.89,
        ];
    }
}
