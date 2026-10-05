<?php

namespace Tests\Feature;

use App\Models\User;
use Tests\TestCase;

class CustomerRegistrationAddressTest extends TestCase
{
    private function payload(array $overrides = []): array
    {
        return $this->withCustomerIdentity(array_merge([
            'name' => 'Maria Santos',
            'email' => 'maria@example.com',
            'phone' => '+639171234570',
            'password' => 'SecureP@ss123',
            'password_confirmation' => 'SecureP@ss123',
            'role' => 'customer',
            'terms_accepted' => '1',
            'privacy_accepted' => '1',
            'address_line_1' => '73 Purok Surngot',
            'address_line_2' => 'Buenavista, Landmark: Near school',
            'city' => 'Claveria',
            'province' => 'Cagayan',
            'zip_code' => '3519',
            'latitude' => '18.607',
            'longitude' => '121.083',
            'is_default' => '1',
        ], $overrides));
    }

    public function test_registration_persists_complete_address_and_referral(): void
    {
        $referrer = User::factory()->create(['referral_code' => 'FRIEND12']);
        $response = $this->post('/api/v1/auth/register', $this->payload([
            'referral_code' => ' friend12 ',
        ]), ['Accept' => 'application/json']);
        $response->assertCreated();

        $user = User::where('email', 'maria@example.com')->sole();
        $this->assertSame($referrer->referral_code, $user->referred_by);
        $address = $user->addresses()->sole();
        $this->assertSame('73 Purok Surngot', $address->address_line1);
        $this->assertSame('Buenavista, Landmark: Near school', $address->address_line2);
        $this->assertSame('Claveria', $address->city);
        $this->assertSame('Cagayan', $address->region);
        $this->assertSame('3519', $address->postal_code);
        $this->assertSame(18.607, $address->latitude);
        $this->assertSame(121.083, $address->longitude);
        $this->assertTrue($address->is_default);
        $this->withToken($response->json('token'))
            ->getJson('/api/v1/users/'.$user->id.'/addresses')
            ->assertOk()->assertJsonPath('data.0.id', $address->id);
    }

    public function test_blank_referral_and_unchecked_default_are_preserved(): void
    {
        $this->post('/api/v1/auth/register', $this->payload([
            'referral_code' => ' ', 'is_default' => '0',
        ]), ['Accept' => 'application/json'])->assertCreated();
        $user = User::where('email', 'maria@example.com')->sole();
        $this->assertNull($user->referred_by);
        $this->assertFalse($user->addresses()->sole()->is_default);
    }

    public function test_unknown_referral_is_rejected_before_account_creation(): void
    {
        $this->post('/api/v1/auth/register', $this->payload([
            'referral_code' => 'UNKNOWN',
        ]), ['Accept' => 'application/json'])
            ->assertUnprocessable()->assertJsonValidationErrors('referral_code');
        $this->assertDatabaseMissing('users', ['email' => 'maria@example.com']);
        $this->assertDatabaseCount('addresses', 0);
    }

    public function test_deleted_referrer_is_rejected(): void
    {
        User::factory()->create(['referral_code' => 'DELETED1'])->delete();
        $this->post('/api/v1/auth/register', $this->payload([
            'referral_code' => 'DELETED1',
        ]), ['Accept' => 'application/json'])
            ->assertUnprocessable()->assertJsonValidationErrors('referral_code');
    }

    public function test_address_without_coordinates_returns_validation_not_server_error(): void
    {
        $this->post('/api/v1/auth/register', $this->payload([
            'latitude' => null, 'longitude' => null,
        ]), ['Accept' => 'application/json'])
            ->assertUnprocessable()->assertJsonValidationErrors(['latitude', 'longitude']);
        $this->assertDatabaseMissing('users', ['email' => 'maria@example.com']);
    }

    public function test_address_failure_rolls_back_the_account_and_referral(): void
    {
        $event = 'eloquent.creating: '.\App\Models\Address::class;
        \Illuminate\Support\Facades\Event::listen($event, function () {
            throw new \RuntimeException('Simulated address write failure');
        });
        try {
            $this->post('/api/v1/auth/register', $this->payload(), [
                'Accept' => 'application/json',
            ])->assertStatus(500);
            $this->assertDatabaseMissing('users', ['email' => 'maria@example.com']);
            $this->assertDatabaseCount('addresses', 0);
            $this->assertDatabaseCount('document_verifications', 0);
        } finally {
            \Illuminate\Support\Facades\Event::forget($event);
        }
    }

    public function test_customer_phone_proof_marks_account_verified_and_cannot_be_reused(): void
    {
        $referrer = User::factory()->create(['referral_code' => 'FRIEND12']);
        $token = \App\Services\RegistrationPhoneProof::issue('+639171234570');
        $this->post('/api/v1/auth/register', $this->payload([
            'phone_verification_token' => $token,
            'referral_code' => 'FRIEND12',
        ]), ['Accept' => 'application/json'])->assertCreated();
        $this->assertNotNull(User::where('email', 'maria@example.com')->sole()->phone_verified_at);
        $this->post('/api/v1/auth/register', $this->payload([
            'email' => 'second@example.com', 'phone_verification_token' => $token,
        ]), ['Accept' => 'application/json'])->assertUnprocessable()
            ->assertJsonValidationErrors('phone_verification_token');
        $this->assertDatabaseMissing('users', ['email' => 'second@example.com']);
        $this->actingAs($referrer, 'sanctum')->getJson('/api/v1/referrals/dashboard')
            ->assertOk()->assertJsonPath('data.friends_joined', 1)
            ->assertJsonPath('data.pending_rewards', 0);
    }

    public function test_customer_rejects_expired_or_wrong_phone_proof(): void
    {
        foreach (['expired', 'wrong_phone'] as $case) {
            $token = \App\Services\RegistrationPhoneProof::issue(
                $case === 'wrong_phone' ? '+639171234599' : '+639171234570'
            );
            if ($case === 'expired') {
                \Illuminate\Support\Facades\DB::table('registration_phone_proofs')
                    ->where('token_hash', hash('sha256', $token))
                    ->update(['expires_at' => now()->subMinute()]);
            }
            $this->post('/api/v1/auth/register', $this->payload([
                'phone_verification_token' => $token,
            ]), ['Accept' => 'application/json'])->assertUnprocessable()
                ->assertJsonValidationErrors('phone_verification_token');
        }
        $this->assertDatabaseMissing('users', ['email' => 'maria@example.com']);
    }
}
