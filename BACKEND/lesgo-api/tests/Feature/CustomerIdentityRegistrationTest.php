<?php

namespace Tests\Feature;

use App\Models\DocumentVerification;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class CustomerIdentityRegistrationTest extends TestCase
{
    public function test_customer_registration_requires_selfie_and_government_id(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Customer Without ID',
            'email' => 'missing-id@example.com',
            'phone_number' => '+639171234570',
            'password' => 'SecureP@ss123',
            'password_confirmation' => 'SecureP@ss123',
            'role' => 'customer',
            'terms_accepted' => true,
            'privacy_accepted' => true,
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors([
                'selfie',
                'id_type',
                'id_number',
                'valid_id_front',
                'valid_id_back',
            ]);
    }

    public function test_customer_registration_stores_selfie_and_pending_id_verification(): void
    {
        $response = $this->post('/api/v1/auth/register', $this->withCustomerIdentity([
            'name' => 'Verified Customer',
            'email' => 'verified-customer@example.com',
            'phone_number' => '+639171234571',
            'password' => 'SecureP@ss123',
            'password_confirmation' => 'SecureP@ss123',
            'role' => 'customer',
            'terms_accepted' => true,
            'privacy_accepted' => true,
        ]), ['Accept' => 'application/json']);

        $response->assertCreated()->assertJsonPath('success', true);

        $user = User::where('email', 'verified-customer@example.com')->sole();
        $this->assertNotNull($user->profile_picture);
        Storage::disk('s3')->assertExists($user->getRawOriginal('profile_picture'));

        $document = DocumentVerification::where('user_id', $user->id)->sole();
        $this->assertSame('valid_id', $document->document_type);
        $this->assertSame('pending', $document->status);
        $this->assertSame('philippine_national_id', $document->metadata['id_type']);
        $this->assertCount(2, $document->document_urls);
    }

    public function test_new_google_customer_is_created_and_must_complete_identity_onboarding(): void
    {
        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response([
                'aud' => config('services.google.client_id'),
                'sub' => 'google-customer-subject',
                'email' => 'google-customer@example.com',
                'email_verified' => 'true',
                'name' => 'Google Customer',
            ]),
        ]);

        $response = $this->postJson('/api/v1/auth/google', [
            'id_token' => 'valid-test-token',
            'device_name' => 'feature-test',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('is_new_user', true)
            ->assertJsonPath('requires_identity_verification', true);

        $user = User::where('email', 'google-customer@example.com')->sole();
        $this->assertNotNull($user->email_verified_at);

        $this->fakeMediaStorage();
        $token = $response->json('token');
        $onboarding = $this->withToken($token)->post('/api/v1/documents/identity-onboarding', [
            'id_type' => 'passport',
            'id_number' => 'P1234567',
            'selfie' => UploadedFile::fake()->image('selfie.jpg'),
            'valid_id_front' => UploadedFile::fake()->image('passport-front.jpg'),
            'valid_id_back' => UploadedFile::fake()->image('passport-back.jpg'),
        ], ['Accept' => 'application/json']);

        $onboarding->assertCreated()->assertJsonPath('success', true);

        $user->refresh();
        $this->assertNotNull($user->profile_picture);
        $this->assertDatabaseHas('document_verifications', [
            'user_id' => $user->id,
            'document_type' => 'valid_id',
            'document_number' => 'P1234567',
            'status' => 'pending',
        ]);
    }

    public function test_google_sign_in_recovers_a_soft_deleted_account_instead_of_creating_a_duplicate(): void
    {
        $user = User::factory()->create([
            'email' => 'returning-google-customer@example.com',
            'role' => 'customer',
            'is_active' => true,
        ]);
        $user->delete();

        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response([
                'aud' => config('services.google.client_id'),
                'sub' => 'returning-google-subject',
                'email' => 'returning-google-customer@example.com',
                'email_verified' => 'true',
                'name' => 'Returning Google Customer',
            ]),
        ]);

        $response = $this->postJson('/api/v1/auth/google', [
            'id_token' => 'valid-returning-token',
            'device_name' => 'feature-test',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('is_new_user', false)
            ->assertJsonPath('requires_identity_verification', true);

        $this->assertSame($user->id, $response->json('user.id'));
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'deleted_at' => null,
        ]);
    }

    public function test_google_login_for_an_existing_customer_skips_registration_onboarding(): void
    {
        $user = User::factory()->create([
            'email' => 'existing-google-customer@example.com',
            'role' => 'customer',
        ]);

        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response([
                'aud' => config('services.google.client_id'),
                'sub' => 'existing-google-subject',
                'email' => $user->email,
                'email_verified' => 'true',
                'name' => 'Existing Google Customer',
            ]),
        ]);

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'valid-existing-token',
            'device_name' => 'feature-test',
            'auth_mode' => 'login',
        ])->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('is_new_user', false)
            ->assertJsonPath('requires_identity_verification', false);
    }

    public function test_google_login_does_not_create_a_missing_account(): void
    {
        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response([
                'aud' => config('services.google.client_id'),
                'sub' => 'unknown-google-subject',
                'email' => 'unknown-google-customer@example.com',
                'email_verified' => 'true',
                'name' => 'Unknown Google Customer',
            ]),
        ]);

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'valid-unknown-token',
            'device_name' => 'feature-test',
            'auth_mode' => 'login',
        ])->assertNotFound()
            ->assertJsonPath('success', false)
            ->assertJsonPath('error_code', 'GOOGLE_ACCOUNT_NOT_FOUND');

        $this->assertDatabaseMissing('users', [
            'email' => 'unknown-google-customer@example.com',
        ]);
    }

    private function fakeMediaStorage(): void
    {
        config([
            'filesystems.media_disk' => 's3',
            'filesystems.disks.s3.key' => 'test-key',
            'filesystems.disks.s3.secret' => 'test-secret',
            'filesystems.disks.s3.bucket' => 'test-bucket',
            'filesystems.disks.s3.url' => 'https://media.example.test',
        ]);
        Storage::fake('s3');
    }
}
