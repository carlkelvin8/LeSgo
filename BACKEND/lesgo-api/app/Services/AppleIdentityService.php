<?php

namespace App\Services;

use App\Models\User;
use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AppleIdentityService
{
    private const ISSUER = 'https://appleid.apple.com';
    private const JWKS_URL = 'https://appleid.apple.com/auth/keys';

    /**
     * Verify a Sign in with Apple identity token and return its claims.
     *
     * @return array<string, mixed>|null
     */
    public function verifyIdToken(string $idToken, ?string $rawNonce = null, ?int $maxAgeSeconds = null): ?array
    {
        $clientId = trim((string) config('services.apple.client_id'));
        if ($clientId === '') {
            Log::error('Apple identity verification is unavailable: APPLE_CLIENT_ID is not configured.');

            return null;
        }

        $claims = $this->decode($idToken, false);
        if ($claims === null) {
            // Apple may have rotated its signing keys since the cached copy.
            $claims = $this->decode($idToken, true);
        }
        if ($claims === null) {
            return null;
        }

        if ($maxAgeSeconds !== null
            && (empty($claims['iat']) || (int) $claims['iat'] < time() - $maxAgeSeconds)) {
            Log::warning('Apple token too old for a sensitive action');

            return null;
        }

        $audience = $claims['aud'] ?? null;
        $audienceMatches = is_array($audience)
            ? in_array($clientId, $audience, true)
            : is_string($audience) && hash_equals($clientId, $audience);

        if (($claims['iss'] ?? null) !== self::ISSUER || ! $audienceMatches || empty($claims['sub'])) {
            Log::warning('Apple token claims rejected');

            return null;
        }

        // Apple hashes the client-supplied raw nonce with SHA-256 into the token.
        if ($rawNonce !== null && $rawNonce !== '') {
            $expected = hash('sha256', $rawNonce);
            if (empty($claims['nonce']) || ! hash_equals($expected, (string) $claims['nonce'])) {
                Log::warning('Apple token nonce mismatch');

                return null;
            }
        }

        $claims['email_verified'] = filter_var($claims['email_verified'] ?? false, FILTER_VALIDATE_BOOL);

        return $claims;
    }

    public function matches(User $user, string $idToken, ?string $rawNonce = null, ?int $maxAgeSeconds = null): bool
    {
        if (empty($user->apple_id)) {
            return false;
        }

        $claims = $this->verifyIdToken($idToken, $rawNonce, $maxAgeSeconds);

        return $claims !== null
            && hash_equals((string) $user->apple_id, (string) $claims['sub']);
    }

    /**
     * Exchange an authorization code for a refresh token and revoke it, so the
     * user's Sign in with Apple grant for this app is removed. Never throws and
     * is skipped when the Apple key credentials are not configured.
     */
    public function revokeAuthorizationCode(string $authorizationCode): bool
    {
        $secret = $this->clientSecret();
        if ($secret === null) {
            Log::info('Apple token revocation skipped: Apple key credentials are not configured.');

            return false;
        }

        $clientId = trim((string) config('services.apple.client_id'));

        try {
            $token = Http::asForm()->timeout(10)->post(self::ISSUER.'/auth/token', [
                'client_id' => $clientId,
                'client_secret' => $secret,
                'code' => $authorizationCode,
                'grant_type' => 'authorization_code',
            ]);

            $refreshToken = $token->successful() ? $token->json('refresh_token') : null;
            if (! $refreshToken) {
                Log::warning('Apple token exchange failed', ['status' => $token->status()]);

                return false;
            }

            $revoke = Http::asForm()->timeout(10)->post(self::ISSUER.'/auth/revoke', [
                'client_id' => $clientId,
                'client_secret' => $secret,
                'token' => $refreshToken,
                'token_type_hint' => 'refresh_token',
            ]);

            return $revoke->successful();
        } catch (\Throwable $e) {
            Log::warning('Apple token revocation error', ['error' => $e->getMessage()]);

            return false;
        }
    }

    private function clientSecret(): ?string
    {
        $teamId = trim((string) config('services.apple.team_id'));
        $keyId = trim((string) config('services.apple.key_id'));
        $privateKey = str_replace('\\n', "\n", (string) config('services.apple.private_key'));
        $clientId = trim((string) config('services.apple.client_id'));

        if ($teamId === '' || $keyId === '' || trim($privateKey) === '' || $clientId === '') {
            return null;
        }

        try {
            return JWT::encode([
                'iss' => $teamId,
                'iat' => time(),
                'exp' => time() + 300,
                'aud' => self::ISSUER,
                'sub' => $clientId,
            ], $privateKey, 'ES256', $keyId);
        } catch (\Throwable $e) {
            Log::warning('Apple client secret could not be created', ['error' => $e->getMessage()]);

            return null;
        }
    }

    /**
     * @return array<string, mixed>|null
     */
    private function decode(string $idToken, bool $refreshKeys): ?array
    {
        // Refresh the key cache at most once a minute so bad tokens cannot
        // be used to hammer Apple's key endpoint.
        if ($refreshKeys && ! Cache::add('apple_auth_jwks_refresh_lock', 1, 60)) {
            return null;
        }

        try {
            $keys = JWK::parseKeySet($this->jwks($refreshKeys), 'RS256');
            JWT::$leeway = 30;

            return (array) JWT::decode($idToken, $keys);
        } catch (\Throwable $e) {
            if ($refreshKeys) {
                Log::warning('Apple token verification failed', ['error' => $e->getMessage()]);
            }

            return null;
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function jwks(bool $refresh = false): array
    {
        if ($refresh) {
            Cache::forget('apple_auth_jwks');
        }

        return Cache::remember('apple_auth_jwks', 3600, function () {
            $response = Http::timeout(10)->get(self::JWKS_URL);
            $response->throw();

            return $response->json();
        });
    }
}
