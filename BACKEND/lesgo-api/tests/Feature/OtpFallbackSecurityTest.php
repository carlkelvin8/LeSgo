<?php

namespace Tests\Feature;

use App\Services\TwilioVerifyService;
use Mockery;
use Tests\TestCase;

class OtpFallbackSecurityTest extends TestCase
{
    use \Illuminate\Foundation\Testing\RefreshDatabase;
    public function test_provider_failure_does_not_silently_create_a_fallback_code(): void
    {
        config(['services.otp.allow_local_fallback' => false]);
        $twilio = Mockery::mock(TwilioVerifyService::class);
        $twilio->shouldReceive('sendVerification')->once()->andReturn([
            'success' => false,
            'message' => 'Provider unavailable',
        ]);
        $this->app->instance(TwilioVerifyService::class, $twilio);

        $this->postJson('/api/v1/auth/otp/send', [
            'phone_number' => '+639171234567',
        ])->assertStatus(503)
            ->assertJsonPath('success', false)
            ->assertJsonMissingPath('otp');

        $this->assertFalse(cache()->has('fallback_otp:639171234567'));
    }

    public function test_explicit_local_fallback_remains_available_for_development(): void
    {
        config(['services.otp.allow_local_fallback' => true]);
        $twilio = Mockery::mock(TwilioVerifyService::class);
        $twilio->shouldReceive('sendVerification')->once()->andReturn([
            'success' => false,
            'message' => 'Provider unavailable',
        ]);
        $this->app->instance(TwilioVerifyService::class, $twilio);

        $send = $this->postJson('/api/v1/auth/otp/send', [
            'phone_number' => '+639181234567',
        ])->assertOk()
            ->assertJsonPath('fallback', true);

        $this->postJson('/api/v1/auth/otp/verify', [
            'phone_number' => '+639181234567',
            'otp' => $send->json('otp'),
        ])->assertOk()
            ->assertJsonPath('verified', true);
    }
}
