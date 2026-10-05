<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WalletLinkedAccount extends Model
{
    protected $fillable = [
        'user_id',
        'provider',
        'account_label',
        'account_last4',
        'is_verified',
        'meta',
        'account_details_encrypted',
    ];

    protected $hidden = [
        'account_details_encrypted',
    ];

    protected $casts = [
        'is_verified' => 'boolean',
        'meta' => 'array',
        'account_details_encrypted' => 'encrypted:array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
