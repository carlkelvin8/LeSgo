<?php

namespace App\Services;

use App\Models\PasswordReset;
use App\Models\RefreshToken;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class PasswordResetService
{
    private const MAX_VERIFICATION_ATTEMPTS = 5;

    /**
     * @return array{challenge: PasswordReset, otp: string}
     */
    public function issue(string $email, ?string $ipAddress): array
    {
        return DB::transaction(function () use ($email, $ipAddress): array {
            PasswordReset::where('email', $email)
                ->where('is_used', false)
                ->update([
                    'is_used' => true,
                    'used_at' => now(),
                    'otp_hash' => null,
                    'reset_token_hash' => null,
                ]);

            $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
            $challenge = PasswordReset::create([
                'email' => $email,
                // Retained only for compatibility with the legacy non-null column.
                // The actual credential is never stored in plaintext.
                'otp' => 'HASHED',
                'otp_hash' => Hash::make($otp),
                'expires_at' => now()->addMinutes(10),
                'ip_address' => $ipAddress,
            ]);

            return compact('challenge', 'otp');
        });
    }

    public function invalidate(PasswordReset $challenge): void
    {
        $challenge->markAsUsed();
    }

    public function verify(string $email, string $otp): ?string
    {
        return DB::transaction(function () use ($email, $otp): ?string {
            $challenge = PasswordReset::where('email', $email)
                ->where('is_used', false)
                ->whereNull('verified_at')
                ->whereNotNull('otp_hash')
                ->where('expires_at', '>', now())
                ->latest('id')
                ->lockForUpdate()
                ->first();

            if (! $challenge) {
                return null;
            }

            if (! Hash::check($otp, $challenge->otp_hash)) {
                $attempts = $challenge->verification_attempts + 1;
                $challenge->verification_attempts = $attempts;

                if ($attempts >= self::MAX_VERIFICATION_ATTEMPTS) {
                    $challenge->is_used = true;
                    $challenge->used_at = now();
                    $challenge->otp_hash = null;
                }

                $challenge->save();

                return null;
            }

            $resetToken = Str::random(64);
            $challenge->update([
                'verified_at' => now(),
                'otp_hash' => null,
                'reset_token' => null,
                'reset_token_hash' => Hash::make($resetToken),
                'reset_token_expires_at' => now()->addMinutes(15),
            ]);

            return $resetToken;
        });
    }

    public function resetPassword(string $email, string $resetToken, string $password): bool
    {
        return DB::transaction(function () use ($email, $resetToken, $password): bool {
            $challenge = PasswordReset::where('email', $email)
                ->where('is_used', false)
                ->whereNotNull('verified_at')
                ->whereNotNull('reset_token_hash')
                ->where('reset_token_expires_at', '>', now())
                ->latest('id')
                ->lockForUpdate()
                ->first();

            if (! $challenge || ! Hash::check($resetToken, $challenge->reset_token_hash)) {
                return false;
            }

            $user = User::where('email', $email)->lockForUpdate()->first();
            if (! $user) {
                $challenge->markAsUsed();

                return false;
            }

            $user->forceFill([
                'password' => Hash::make($password),
            ])->save();
            $user->tokens()->delete();
            RefreshToken::query()
                ->where('user_id', $user->id)
                ->whereNull('revoked_at')
                ->update(['revoked_at' => now()]);
            $challenge->markAsUsed();

            return true;
        });
    }
}
