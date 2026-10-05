<?php

namespace Tests\Feature;

use App\Models\TwoFactorAuth;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use PragmaRX\Google2FA\Google2FA;
use Tests\TestCase;

class TwoFactorAuthenticationTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_does_not_issue_tokens_until_totp_is_supplied(): void
    {
        [$user] = $this->userWithTotp();

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'Secret123!',
        ]);

        $response->assertStatus(202)
            ->assertJsonPath('success', false)
            ->assertJsonPath('two_factor_required', true)
            ->assertJsonMissingPath('token');
        $this->assertSame(0, $user->tokens()->count());
    }

    public function test_customer_can_enroll_google_authenticator(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $token = $user->createToken('test')->plainTextToken;

        $setup = $this->withToken($token)
            ->postJson('/api/v1/security/2fa/setup')
            ->assertOk()
            ->assertJsonCount(8, 'data.backup_codes')
            ->json('data');

        $this->assertStringStartsWith('otpauth://totp/', $setup['qr_code_url']);
        $twoFactor = TwoFactorAuth::where('user_id', $user->id)->firstOrFail();
        $this->assertFalse($twoFactor->is_enabled);
        $this->assertTrue(Hash::check($setup['backup_codes'][0], $twoFactor->backup_codes[0]));

        $secret = decrypt($twoFactor->secret);
        $this->withToken($token)
            ->postJson('/api/v1/security/2fa/verify', [
                'code' => (new Google2FA())->getCurrentOtp($secret),
            ])
            ->assertOk()
            ->assertJsonPath('data.2fa_enabled', true);

        $this->assertTrue($twoFactor->fresh()->is_enabled);
    }

    public function test_enabling_two_factor_revokes_refresh_tokens_created_before_enrollment(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $tokens = app(\App\Services\AuthenticationService::class)->issueTokenPair($user, 'test-device');
        $this->withToken($tokens['token'])
            ->postJson('/api/v1/security/2fa/setup')
            ->assertOk()
            ->json('data');
        $twoFactor = TwoFactorAuth::where('user_id', $user->id)->firstOrFail();

        $this->withToken($tokens['token'])
            ->postJson('/api/v1/security/2fa/verify', [
                'code' => (new Google2FA())->getCurrentOtp(decrypt($twoFactor->secret)),
            ])->assertOk();

        $this->postJson('/api/v1/auth/refresh', [
            'refresh_token' => $tokens['refresh_token'],
            'device_name' => 'test-device',
        ])->assertUnauthorized();
    }

    public function test_access_token_refresh_requires_a_fresh_two_factor_code(): void
    {
        [$user, $secret] = $this->userWithTotp();
        $token = $user->createToken('test-device')->plainTextToken;

        $this->withToken($token)
            ->postJson('/api/v1/auth/refresh')
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['two_factor_code']);

        $this->withToken($token)
            ->postJson('/api/v1/auth/refresh', [
                'two_factor_code' => (new Google2FA())->getCurrentOtp($secret),
                'device_name' => 'test-device',
            ])->assertOk()
            ->assertJsonStructure(['token', 'refresh_token']);
    }

    public function test_login_rejects_an_invalid_totp_without_issuing_tokens(): void
    {
        [$user] = $this->userWithTotp();

        $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'Secret123!',
            'two_factor_code' => '000000',
        ])->assertStatus(422)
            ->assertJsonPath('two_factor_required', true);

        $this->assertSame(0, $user->tokens()->count());
    }

    public function test_login_accepts_a_google_authenticator_code(): void
    {
        [$user, $secret] = $this->userWithTotp();
        $code = (new Google2FA())->getCurrentOtp($secret);

        $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'Secret123!',
            'two_factor_code' => $code,
        ])->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['token', 'refresh_token', 'user']);

        $this->assertSame(1, $user->tokens()->count());
    }

    public function test_backup_codes_are_hashed_and_can_only_be_used_once(): void
    {
        [$user] = $this->userWithTotp();
        $twoFactor = TwoFactorAuth::where('user_id', $user->id)->firstOrFail();
        $backupCode = $twoFactor->generateBackupCodes(1)[0];

        $twoFactor->refresh();
        $this->assertNotSame($backupCode, $twoFactor->backup_codes[0]);
        $this->assertTrue(Hash::check($backupCode, $twoFactor->backup_codes[0]));

        $payload = [
            'email' => $user->email,
            'password' => 'Secret123!',
            'two_factor_code' => $backupCode,
        ];

        $this->postJson('/api/v1/auth/login', $payload)->assertOk();
        $this->assertSame([], $twoFactor->fresh()->backup_codes);
        $this->postJson('/api/v1/auth/login', $payload)
            ->assertStatus(422)
            ->assertJsonPath('two_factor_required', true);
    }

    public function test_disabling_two_factor_requires_a_valid_code(): void
    {
        [$user, $secret] = $this->userWithTotp();
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->postJson('/api/v1/security/2fa/disable')
            ->assertStatus(422);
        $this->assertDatabaseHas('two_factor_auth', [
            'user_id' => $user->id,
            'is_enabled' => true,
        ]);

        $this->withToken($token)
            ->postJson('/api/v1/security/2fa/disable', [
                'code' => (new Google2FA())->getCurrentOtp($secret),
            ])
            ->assertOk()
            ->assertJsonPath('data.2fa_enabled', false);

        $this->assertDatabaseMissing('two_factor_auth', ['user_id' => $user->id]);
    }

    public function test_regenerating_backup_codes_requires_a_valid_code(): void
    {
        [$user, $secret] = $this->userWithTotp();
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->postJson('/api/v1/security/2fa/backup-codes/regenerate')
            ->assertStatus(422);

        $codes = $this->withToken($token)
            ->postJson('/api/v1/security/2fa/backup-codes/regenerate', [
                'code' => (new Google2FA())->getCurrentOtp($secret),
            ])
            ->assertOk()
            ->assertJsonCount(8, 'data.backup_codes')
            ->json('data.backup_codes');

        $storedCodes = TwoFactorAuth::where('user_id', $user->id)
            ->firstOrFail()
            ->backup_codes;
        $this->assertTrue(Hash::check($codes[0], $storedCodes[0]));
    }

    public function test_customer_security_dashboard_returns_account_security_state(): void
    {
        [$user] = $this->userWithTotp();
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->getJson('/api/v1/security/dashboard')
            ->assertOk()
            ->assertJsonPath('data.two_factor_enabled', true)
            ->assertJsonPath('data.biometric_enabled', false)
            ->assertJsonPath('data.active_sessions', 1)
            ->assertJsonStructure([
                'data' => [
                    'two_factor_enabled',
                    'biometric_enabled',
                    'active_sessions',
                    'last_login',
                    'last_password_change',
                ],
            ]);
    }

    /**
     * @return array{User, string}
     */
    private function userWithTotp(): array
    {
        $user = User::factory()->create([
            'role' => 'customer',
            'password' => bcrypt('Secret123!'),
        ]);
        $secret = (new Google2FA())->generateSecretKey();

        TwoFactorAuth::create([
            'user_id' => $user->id,
            'method' => 'totp',
            'secret' => encrypt($secret),
            'is_enabled' => true,
            'enabled_at' => now(),
        ]);

        return [$user, $secret];
    }
}
