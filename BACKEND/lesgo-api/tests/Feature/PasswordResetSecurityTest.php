<?php

namespace Tests\Feature;

use App\Mail\PasswordResetOtpMail;
use App\Models\PasswordReset;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class PasswordResetSecurityTest extends TestCase
{
    public function test_password_reset_uses_hashed_single_use_credentials(): void
    {
        Mail::fake();
        $user = User::factory()->create([
            'email' => 'reset@example.com',
            'password' => Hash::make('OldPassword123'),
        ]);
        $user->createToken('existing-session');

        $this->postJson('/api/v1/auth/forgot-password/send-otp', [
            'email' => 'RESET@example.com',
        ])->assertOk()->assertJsonPath('success', true);

        $otp = null;
        Mail::assertSent(PasswordResetOtpMail::class, function (PasswordResetOtpMail $mail) use (&$otp): bool {
            $otp = $mail->otp;

            return true;
        });
        $this->assertMatchesRegularExpression('/^\d{6}$/', $otp);

        $challenge = PasswordReset::sole();
        $this->assertSame('HASHED', $challenge->otp);
        $this->assertNull($challenge->reset_token);
        $this->assertNotSame($otp, $challenge->otp_hash);
        $this->assertTrue(Hash::check($otp, $challenge->otp_hash));

        $verification = $this->postJson('/api/v1/auth/forgot-password/verify-otp', [
            'email' => $user->email,
            'otp' => $otp,
        ])->assertOk()->assertJsonPath('success', true);
        $resetToken = $verification->json('reset_token');
        $this->assertIsString($resetToken);
        $this->assertSame(64, strlen($resetToken));

        $challenge->refresh();
        $this->assertNull($challenge->otp_hash);
        $this->assertNull($challenge->reset_token);
        $this->assertTrue(Hash::check($resetToken, $challenge->reset_token_hash));

        $this->postJson('/api/v1/auth/forgot-password/reset', [
            'email' => $user->email,
            'otp' => $otp,
            'password' => 'NewPassword123',
            'password_confirmation' => 'NewPassword123',
        ])->assertUnprocessable()->assertJsonValidationErrors('reset_token');

        $payload = [
            'email' => $user->email,
            'reset_token' => $resetToken,
            'password' => 'NewPassword123',
            'password_confirmation' => 'NewPassword123',
        ];
        $this->postJson('/api/v1/auth/forgot-password/reset', $payload)
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertTrue(Hash::check('NewPassword123', $user->fresh()->password));
        $this->assertSame(0, $user->tokens()->count());
        $this->assertTrue($challenge->fresh()->is_used);

        $this->postJson('/api/v1/auth/forgot-password/reset', $payload)
            ->assertUnprocessable()
            ->assertJsonPath('success', false);
    }

    public function test_password_reset_response_does_not_disclose_unknown_email(): void
    {
        Mail::fake();

        $known = User::factory()->create(['email' => 'known@example.com']);
        $knownResponse = $this->postJson('/api/v1/auth/forgot-password/send-otp', [
            'email' => $known->email,
        ])->assertOk();
        $unknownResponse = $this->postJson('/api/v1/auth/forgot-password/send-otp', [
            'email' => 'unknown@example.com',
        ])->assertOk();

        $this->assertSame($knownResponse->json('message'), $unknownResponse->json('message'));
        $this->assertDatabaseMissing('password_resets', ['email' => 'unknown@example.com']);
    }

    public function test_password_reset_challenge_locks_after_repeated_invalid_codes(): void
    {
        Mail::fake();
        $user = User::factory()->create(['email' => 'locked@example.com']);

        $this->postJson('/api/v1/auth/forgot-password/send-otp', ['email' => $user->email])
            ->assertOk();

        foreach (range(1, 5) as $attempt) {
            $this->postJson('/api/v1/auth/forgot-password/verify-otp', [
                'email' => $user->email,
                'otp' => '000000',
            ])->assertUnprocessable();
        }

        $challenge = PasswordReset::sole();
        $this->assertTrue($challenge->is_used);
        $this->assertSame(5, $challenge->verification_attempts);
        $this->assertNull($challenge->otp_hash);
    }
}
