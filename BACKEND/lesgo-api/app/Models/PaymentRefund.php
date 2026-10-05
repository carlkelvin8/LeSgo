<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentRefund extends Model
{
    public const RESERVED_STATUSES = ['processing', 'submitted', 'verification_required', 'completed'];

    protected $fillable = [
        'payment_id',
        'requested_by',
        'amount',
        'currency',
        'provider',
        'payment_reference',
        'idempotency_key',
        'gateway_reference',
        'status',
        'reason',
        'failure_reason',
        'completed_at',
        'meta',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'completed_at' => 'datetime',
        'meta' => 'array',
    ];

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class);
    }

    public function requester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requested_by');
    }
}
