<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WalletWithdrawal extends Model
{
    public const ACTIVE_STATUSES = ['processing', 'submitted', 'verification_required'];

    protected $fillable = [
        'user_id',
        'wallet_id',
        'amount',
        'currency',
        'status',
        'provider',
        'withdrawal_method',
        'external_reference',
        'gateway_reference',
        'account_last4',
        'failure_reason',
        'debited_at',
        'completed_at',
        'failed_at',
        'reversed_at',
        'meta',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'debited_at' => 'datetime',
        'completed_at' => 'datetime',
        'failed_at' => 'datetime',
        'reversed_at' => 'datetime',
        'meta' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function wallet(): BelongsTo
    {
        return $this->belongsTo(Wallet::class);
    }
}
