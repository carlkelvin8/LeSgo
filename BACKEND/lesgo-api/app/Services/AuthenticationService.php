<?php

namespace App\Services;

use App\Models\RefreshToken;
use App\Models\User;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Schema;

class AuthenticationService
{
    /**
     * Maximum failed login attempts before lockout.
     */
    private const MAX_ATTEMPTS = 5;

    /**
     * Lockout duration in seconds.
     */
    private const LOCKOUT_SECONDS = 300; // 5 minutes

    /**
     * Default refresh token lifetime in days.
     */
    private const REFRESH_TOKEN_DAYS = 30;

    /**
     * Attempt to authenticate a user.
     */
    public function authenticate(
        string $email,
        string $password,
        string $ip,
        bool $logSuccessfulLogin = true
    ): User {
        $key = $this->throttleKey($email, $ip);

        // Check if too many attempts
        if (RateLimiter::tooManyAttempts($key, self::MAX_ATTEMPTS)) {
            $seconds = RateLimiter::availableIn($key);

            $this->logFailedAttempt($email, $ip);

            throw new ThrottleRequestsException(
                "Too many login attempts. Please try again in {$seconds} seconds.",
                null,
                ['Retry-After' => $seconds]
            );
        }

        $user = User::where('email', $email)->first();

        if (! $user || ! Hash::check($password, $user->password)) {
            RateLimiter::hit($key, self::LOCKOUT_SECONDS);

            $this->logFailedAttempt($email, $ip);

            throw new AuthenticationException('The provided credentials are incorrect.');
        }

        // Check if account is active
        if ($user->is_active === false) {
            throw new AuthenticationException('Your account has been deactivated. Please contact support.');
        }

        if ($this->isAccountDeleted($user)) {
            throw new AuthenticationException('This account has been deleted.');
        }

        // Clear rate limiter on successful login
        RateLimiter::clear($key);

        if ($logSuccessfulLogin) {
            AuditLogger::logAuth('login', $user->id, true);
        }

        return $user;
    }

    /**
     * Create authentication token for user.
     */
    public function createToken(User $user, string $deviceName, array $abilities = ['*']): string
    {
        return $user->createToken($deviceName, $abilities)->plainTextToken;
    }

    /**
     * Create access + refresh token pair for API clients.
     *
     * @return array{token: string, refresh_token: string, expires_in: int}
     */
    public function issueTokenPair(User $user, string $deviceName): array
    {
        return [
            'token' => $this->createToken($user, $deviceName),
            'refresh_token' => $this->createRefreshToken($user, $deviceName),
            'expires_in' => 3600,
        ];
    }

    /**
     * Create a long-lived refresh token for the user.
     */
    public function createRefreshToken(User $user, string $deviceName): string
    {
        $plainToken = bin2hex(random_bytes(32));

        RefreshToken::create([
            'user_id' => $user->id,
            'token_hash' => hash('sha256', $plainToken),
            'device_name' => $deviceName,
            'expires_at' => now()->addDays(self::REFRESH_TOKEN_DAYS),
        ]);

        return $plainToken;
    }

    /**
     * Issue a new access + refresh token pair, revoking the consumed refresh token.
     *
     * @return array{user: User, accessToken: string, refreshToken: string}
     */
    public function rotateRefreshToken(string $plainToken, string $deviceName = 'api-token'): array
    {
        $result = DB::transaction(function () use ($plainToken, $deviceName): array {
            $record = RefreshToken::query()
                ->where('token_hash', hash('sha256', $plainToken))
                ->whereNull('revoked_at')
                ->where('expires_at', '>', now())
                ->lockForUpdate()
                ->first();

            if (! $record) {
                return ['error' => 'Invalid or expired refresh token.'];
            }

            $user = User::query()->lockForUpdate()->find($record->user_id);
            if (! $user || $user->is_active === false) {
                $record->update(['revoked_at' => now()]);
                return ['error' => 'Account is deactivated.'];
            }

            if ($this->isAccountDeleted($user)) {
                $record->update(['revoked_at' => now()]);
                return ['error' => 'This account has been deleted.'];
            }

            $record->update(['revoked_at' => now()]);
            // Access tokens created for this device are rotated with its refresh
            // token. A replayed refresh token cannot leave the prior bearer live.
            $user->tokens()->where('name', $deviceName)->delete();

            return [
                'user' => $user,
                'accessToken' => $this->createToken($user, $deviceName),
                'refreshToken' => $this->createRefreshToken($user, $deviceName),
            ];
        });
        if (isset($result['error'])) {
            throw new AuthenticationException($result['error']);
        }

        return $result;
    }

    /**
     * Revoke all refresh tokens for a user.
     */
    public function revokeAllRefreshTokens(User $user): void
    {
        RefreshToken::query()
            ->where('user_id', $user->id)
            ->whereNull('revoked_at')
            ->update(['revoked_at' => now()]);
    }

    /**
     * Revoke all tokens for a user (useful on password change).
     */
    public function revokeAllTokens(User $user): void
    {
        $user->tokens()->delete();
        $this->revokeAllRefreshTokens($user);

        AuditLogger::logAuth('tokens_revoked', $user->id, true);
    }

    /**
     * Revoke current token.
     */
    public function revokeCurrentToken(User $user, ?string $plainToken = null): void
    {
        $currentToken = $user->currentAccessToken();
        $deviceName = $currentToken?->name;
        if ($currentToken && method_exists($currentToken, 'delete')) {
            $currentToken->delete();
        }

        if ($plainToken !== null && str_contains($plainToken, '|')) {
            [$tokenId, $tokenSecret] = explode('|', $plainToken, 2);
            $user->tokens()
                ->whereKey($tokenId)
                ->where('token', hash('sha256', $tokenSecret))
                ->delete();
            $deviceName = $deviceName ?: $user->tokens()->whereKey($tokenId)->value('name');
        }

        // Access and refresh tokens share the device name. Revoke the pair for
        // this device on logout; otherwise its refresh token can mint a new one.
        if ($deviceName) {
            $user->tokens()->where('name', $deviceName)->delete();
            RefreshToken::query()
                ->where('user_id', $user->id)
                ->where('device_name', $deviceName)
                ->whereNull('revoked_at')
                ->update(['revoked_at' => now()]);
        }

        AuditLogger::logAuth('logout', $user->id, true);
    }

    public function revokeCurrentAccessToken(User $user): void
    {
        $token = $user->currentAccessToken();
        if ($token && method_exists($token, 'delete')) {
            $token->delete();
        }
    }

    /**
     * Generate throttle key for rate limiting.
     */
    private function throttleKey(string $email, string $ip): string
    {
        return 'login:'.strtolower($email).'|'.$ip;
    }

    /**
     * Log failed login attempt.
     */
    private function logFailedAttempt(string $email, string $ip): void
    {
        try {
            DB::table('failed_login_attempts')->insert([
                'email' => $email,
                'ip_address' => $ip,
                'user_agent' => request()->userAgent(),
                'attempted_at' => now(),
            ]);
        } catch (\Throwable) {
            // Non-critical — don't let logging crash the auth flow
        }

        AuditLogger::logAuth('login_failed', null, false);
    }

    private function isAccountDeleted(User $user): bool
    {
        if (Schema::hasColumn('users', 'deleted_at') && $user->deleted_at !== null) {
            return true;
        }

        return str_ends_with(strtolower((string) $user->email), '@deleted.local');
    }
}
