<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RegistrationFeePayment extends Model
{
    use \App\Models\Concerns\HasAnnualPartnerFee;

    protected $table = 'registration_fee_payments';

    protected $fillable = [
        'user_id',
        'account_type',
        'amount',
        'currency',
        'paymongo_checkout_id',
        'paymongo_reference',
        'idempotency_key',
        'checkout_url',
        'payment_status',
        'payment_date',
        'waived_at',
        'waived_by',
        'waiver_reason',
        'application_status',
        'approved_at',
        'approved_by',
        'activated_at',
        'is_active',
        'is_grandfathered',
        'failure_reason',
        'metadata',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'payment_date' => 'datetime',
        'waived_at' => 'datetime',
        'approved_at' => 'datetime',
        'activated_at' => 'datetime',
        'is_active' => 'boolean',
        'is_grandfathered' => 'boolean',
        'metadata' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public const PAYMENT_UNPAID = 'unpaid';
    public const PAYMENT_PENDING = 'pending';
    public const PAYMENT_PAID = 'paid';
    public const PAYMENT_WAIVED = 'waived';
    public const PAYMENT_FAILED = 'failed';
    public const PAYMENT_EXPIRED = 'expired';

    public const APP_PENDING = 'pending';
    public const APP_APPROVED = 'approved';
    public const APP_REJECTED = 'rejected';

    public const TYPE_RIDER = 'rider';
    public const TYPE_MERCHANT = 'merchant';

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function approver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function waivedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'waived_by');
    }

    public function isPaid(): bool
    {
        return $this->payment_status === self::PAYMENT_PAID;
    }

    public function isWaived(): bool
    {
        return $this->payment_status === self::PAYMENT_WAIVED;
    }

    public function isFeeSatisfied(): bool
    {
        return ($this->isPaid() || $this->isWaived()) && !$this->annualRenewalDue();
    }

    public function isApproved(): bool
    {
        return $this->application_status === self::APP_APPROVED;
    }

    public function shouldBeActive(): bool
    {
        return $this->isApproved() && $this->isFeeSatisfied();
    }

    public function displayAccountStatus(): string
    {
        return $this->is_active ? 'Active' : 'Restricted';
    }

    public function displayPaymentStatusLabel(): string
    {
        return ucfirst($this->payment_status);
    }

    public function displayCombinedStatus(): string
    {
        if ($this->is_active) {
            return 'Active';
        }
        if ($this->isFeeSatisfied() && $this->application_status === self::APP_PENDING) {
            return ($this->isWaived() ? 'Registration Fee Waived' : 'Payment Successful') . ' – Application Pending Approval';
        }
        if ($this->isApproved() && !$this->isFeeSatisfied()) {
            return 'Application Approved – Registration Fee Payment Required';
        }
        if ($this->application_status === self::APP_REJECTED) {
            return 'Application Rejected';
        }
        if ($this->payment_status === self::PAYMENT_FAILED) {
            return 'Payment Failed – Please retry';
        }
        if ($this->payment_status === self::PAYMENT_PENDING) {
            return 'Payment Pending – Awaiting PayMongo confirmation';
        }
        return 'Restricted – Payment and Approval Required';
    }
}
