<?php

namespace Tests\Feature;

use App\Models\User;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class AppleSignInTest extends TestCase
{
    private const CLIENT_ID = 'com.lesgo.app';
    private const NONCE = 'raw-nonce-0123456789abcdef';

    private string $privateKey;
    private string $kid = 'test-key-1';

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.apple.client_id' => self::CLIENT_ID]);
        Cache::flush();

        $key = openssl_pkey_new(['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA]);
        openssl_pkey_export($key, $pem);
        $this->privateKey = $pem;
        $details = openssl_pkey_get_details($key);

        Http::fake([
            'appleid.apple.com/auth/keys' => Http::response(['keys' => [[
                'kty' => 'RSA', 'kid' => $this->kid, 'use' => 'sig', 'alg' => 'RS256',
                'n' => rtrim(strtr(base64_encode($details['rsa']['n']), '+/', '-_'), '='),
                'e' => rtrim(strtr(base64_encode($details['rsa']['e']), '+/', '-_'), '='),
            ]]]),
        ]);
    }

    private function appleToken(array $overrides = [], ?string $nonce = self::NONCE): string
    {
        $claims = array_merge([
            'iss' => 'https://appleid.apple.com',
            'aud' => self::CLIENT_ID,
            'sub' => 'apple-subject-1',
            'email' => 'apple.user@example.com',
            'email_verified' => 'true',
            'iat' => time(),
            'exp' => time() + 600,
        ], $overrides);
        if ($nonce !== null) {
            $claims['nonce'] = hash('sha256', $nonce);
        }

        return JWT::encode($claims, $this->privateKey, 'RS256', $this->kid);
    }

    public function test_existing_user_can_login_and_gets_apple_id_linked_by_verified_email(): void
    {
        $user = User::factory()->create(['email' => 'apple.user@example.com']);

        $this->postJson('/api/v1/auth/apple', [
            'id_token' => $this->appleToken(), 'nonce' => self::NONCE, 'auth_mode' => 'login',
        ])->assertOk()->assertJsonPath('success', true)->assertJsonStructure(['token', 'refresh_token']);

        $this->assertSame('apple-subject-1', $user->fresh()->apple_id);
    }

    public function test_login_never_creates_an_account_but_signup_does(): void
    {
        $this->postJson('/api/v1/auth/apple', [
            'id_token' => $this->appleToken(), 'nonce' => self::NONCE, 'auth_mode' => 'login',
        ])->assertNotFound()->assertJsonPath('error_code', 'APPLE_ACCOUNT_NOT_FOUND');
        $this->assertDatabaseMissing('users', ['email' => 'apple.user@example.com']);

        $this->postJson('/api/v1/auth/apple', [
            'id_token' => $this->appleToken(), 'nonce' => self::NONCE,
            'auth_mode' => 'signup', 'full_name' => 'Apple Person',
        ])->assertOk()->assertJsonPath('is_new_user', true);
        $this->assertDatabaseHas('users', [
            'email' => 'apple.user@example.com', 'apple_id' => 'apple-subject-1', 'role' => 'customer',
        ]);
    }

    public function test_second_login_matches_by_apple_id_even_if_email_is_a_private_relay(): void
    {
        $user = User::factory()->create(['email' => 'x@example.com', 'apple_id' => 'apple-subject-1']);

        $this->postJson('/api/v1/auth/apple', [
            'id_token' => $this->appleToken(['email' => 'abc@privaterelay.appleid.com']),
            'nonce' => self::NONCE, 'auth_mode' => 'login',
        ])->assertOk()->assertJsonPath('user.id', $user->id);
    }

    public function test_rejects_wrong_audience_issuer_nonce_signature_and_expiry(): void
    {
        $cases = [
            'audience' => [$this->appleToken(['aud' => 'com.other.app']), self::NONCE],
            'issuer' => [$this->appleToken(['iss' => 'https://evil.example']), self::NONCE],
            'nonce' => [$this->appleToken(), 'a-different-nonce-0123456789'],
            'expired' => [$this->appleToken(['exp' => time() - 3600, 'iat' => time() - 4000]), self::NONCE],
            'garbage' => ['not.a.jwt', self::NONCE],
        ];

        foreach ($cases as $name => [$token, $nonce]) {
            Cache::flush();
            $this->postJson('/api/v1/auth/apple', [
                'id_token' => $token, 'nonce' => $nonce, 'auth_mode' => 'signup',
            ])->assertUnauthorized();
            $this->assertDatabaseMissing('users', ['email' => 'apple.user@example.com']);
        }
    }

    public function test_nonce_is_required(): void
    {
        $this->postJson('/api/v1/auth/apple', [
            'id_token' => $this->appleToken(), 'auth_mode' => 'signup',
        ])->assertUnprocessable();
    }

    public function test_email_account_with_a_different_apple_identity_is_not_taken_over(): void
    {
        User::factory()->create(['email' => 'apple.user@example.com', 'apple_id' => 'someone-else']);

        $this->postJson('/api/v1/auth/apple', [
            'id_token' => $this->appleToken(), 'nonce' => self::NONCE, 'auth_mode' => 'login',
        ])->assertUnauthorized();
    }

    public function test_inactive_account_is_forbidden(): void
    {
        User::factory()->create([
            'email' => 'apple.user@example.com', 'apple_id' => 'apple-subject-1', 'is_active' => false,
        ]);

        $this->postJson('/api/v1/auth/apple', [
            'id_token' => $this->appleToken(), 'nonce' => self::NONCE, 'auth_mode' => 'login',
        ])->assertForbidden();
    }

    public function test_apple_user_can_delete_account_with_fresh_token_and_apple_id_is_cleared(): void
    {
        $user = User::factory()->create(['apple_id' => 'apple-subject-1', 'role' => 'customer']);

        $this->actingAsSanctum($user)->postJson('/api/v1/auth/account/delete', [
            'apple_id_token' => $this->appleToken(), 'apple_nonce' => self::NONCE, 'confirmation' => 'DELETE',
        ])->assertOk();

        $this->assertNull($user->fresh()->apple_id);
        $this->assertStringEndsWith('@deleted.local', $user->fresh()->email);
    }

    public function test_deletion_rejects_stale_wrong_subject_or_missing_nonce_tokens(): void
    {
        $user = User::factory()->create(['apple_id' => 'apple-subject-1', 'role' => 'customer']);

        $attempts = [
            [$this->appleToken(['iat' => time() - 3600, 'exp' => time() + 600]), self::NONCE],
            [$this->appleToken(['sub' => 'another-subject']), self::NONCE],
        ];
        foreach ($attempts as [$token, $nonce]) {
            $this->actingAsSanctum($user)->postJson('/api/v1/auth/account/delete', [
                'apple_id_token' => $token, 'apple_nonce' => $nonce, 'confirmation' => 'DELETE',
            ])->assertUnprocessable();
        }

        $this->actingAsSanctum($user)->postJson('/api/v1/auth/account/delete', [
            'apple_id_token' => $this->appleToken(), 'confirmation' => 'DELETE',
        ])->assertUnprocessable();

        $this->assertSame('apple-subject-1', $user->fresh()->apple_id);
        $this->assertNull($user->fresh()->deleted_at);
    }

    public function test_apple_user_can_deactivate_with_fresh_token(): void
    {
        $user = User::factory()->create(['apple_id' => 'apple-subject-1']);

        $this->actingAsSanctum($user)->postJson('/api/v1/auth/account/deactivate', [
            'apple_id_token' => $this->appleToken(), 'apple_nonce' => self::NONCE,
        ])->assertOk();

        $this->assertFalse($user->fresh()->is_active);
    }

    public function test_revocation_is_skipped_without_credentials_and_never_blocks_deletion(): void
    {
        config(['services.apple.team_id' => null, 'services.apple.key_id' => null, 'services.apple.private_key' => null]);
        $user = User::factory()->create(['apple_id' => 'apple-subject-1', 'role' => 'customer']);

        $this->actingAsSanctum($user)->postJson('/api/v1/auth/account/delete', [
            'apple_id_token' => $this->appleToken(), 'apple_nonce' => self::NONCE,
            'apple_authorization_code' => 'code-123', 'confirmation' => 'DELETE',
        ])->assertOk();

        Http::assertNotSent(fn ($request) => str_contains($request->url(), '/auth/revoke'));
    }

    public function test_apple_id_is_never_serialized_and_migration_is_idempotent(): void
    {
        $user = User::factory()->create(['apple_id' => 'apple-subject-1']);
        $this->assertArrayNotHasKey('apple_id', $user->toArray());

        $migration = require database_path('migrations/2026_10_12_000001_add_apple_id_to_users_table.php');
        $migration->up(); // column already exists: must be a no-op, not an error
        $this->assertTrue(Schema::hasColumn('users', 'apple_id'));
    }

    private function actingAsSanctum(User $user): static
    {
        return $this->withToken($user->createToken('test')->plainTextToken);
    }
}
