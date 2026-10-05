<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\RegistrationDocumentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class OtpVerificationPrivacyTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_clients_cannot_query_phone_verification_status(): void
    {
        $this->postJson('/api/v1/auth/otp/check', [
            'phone_number' => '+639171234567',
        ])->assertUnauthorized();
    }

    public function test_authenticated_user_can_only_query_their_own_phone_status(): void
    {
        $user = User::factory()->create([
            'role' => 'customer',
            'phone_number' => '+639171234567',
        ]);
        Cache::put(RegistrationDocumentService::phoneVerificationCacheKey($user->phone_number), true, now()->addMinutes(5));

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/auth/otp/check', ['phone_number' => $user->phone_number])
            ->assertOk()
            ->assertJsonPath('verified', true);

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/auth/otp/check', ['phone_number' => '+639181234567'])
            ->assertNotFound()
            ->assertJsonMissingPath('verified');
    }
}
