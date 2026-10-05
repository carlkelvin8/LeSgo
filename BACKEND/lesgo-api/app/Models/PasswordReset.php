<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PasswordReset extends Model
{
    protected $fillable = [
        'email',
        'otp',
        'otp_hash',
        'verification_attempts',
        'verified_at',
        'reset_token',
        'reset_token_hash',
        'reset_token_expires_at',
        'expires_at',
        'is_used',
        'used_at',
        'ip_address',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'reset_token_expires_at' => 'datetime',
        'verified_at' => 'datetime',
        'used_at' => 'datetime',
        'is_used' => 'boolean',
        'verification_attempts' => 'integer',
    ];

    protected $hidden = [
        'otp',
        'otp_hash',
        'reset_token',
        'reset_token_hash',
    ];

    /**
     * Check if OTP is expired
     */
    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    /**
     * Check if OTP is valid (not used and not expired)
     */
    public function isValid(): bool
    {
        return ! $this->is_used && ! $this->isExpired();
    }

    /**
     * Mark OTP as used
     */
    public function markAsUsed(): void
    {
        $this->update([
            'is_used' => true,
            'used_at' => now(),
            'otp_hash' => null,
            'reset_token_hash' => null,
        ]);
    }
}
