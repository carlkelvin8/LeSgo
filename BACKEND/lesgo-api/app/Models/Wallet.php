<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Wallet extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'balance',
        'currency',
    ];

    protected $casts = [
        'balance'    => 'decimal:2',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function transactions()
    {
        return $this->hasMany(WalletTransaction::class, 'wallet_id');
    }

    public function withdrawalRequests()
    {
        return $this->hasMany(MerchantWithdrawalRequest::class, 'wallet_id');
    }

    /**
     * Calculate available balance.
     *
     * Withdrawal funds are debited from the wallet as soon as the request is
     * created (and credited back if it is cancelled), so the wallet balance is
     * already net of any pending/processing withdrawals.
     */
    public function availableBalance(): float
    {
        return (float) $this->balance;
    }

    /**
     * Get total pending withdrawal amount
     */
    public function pendingWithdrawalAmount(): float
    {
        return $this->withdrawalRequests()
            ->whereIn('status', [
                MerchantWithdrawalRequest::STATUS_PENDING,
                MerchantWithdrawalRequest::STATUS_PROCESSING,
            ])
            ->sum('amount');
    }

    /**
     * Check if wallet has sufficient available balance
     */
    public function hasSufficientBalance(float $amount): bool
    {
        return $this->availableBalance() >= $amount;
    }
}
