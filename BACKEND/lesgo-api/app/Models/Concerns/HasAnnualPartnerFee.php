<?php

namespace App\Models\Concerns;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

trait HasAnnualPartnerFee
{
    public const PARTNER_ANNUAL_FEE = 1000.00;

    public function getRegistrationExpiresAtAttribute(): ?Carbon
    {
        if ($this->account_type !== self::TYPE_MERCHANT || $this->is_grandfathered
            || (!$this->isPaid() && !$this->isWaived())) {
            return null;
        }

        $start = $this->isWaived() ? $this->waived_at : $this->payment_date;
        $start ??= $this->activated_at ?? $this->created_at;

        return $start ? Carbon::parse($start)->addYearNoOverflow() : null;
    }

    public function annualRenewalDue(): bool
    {
        return $this->registration_expires_at?->lte(now()) ?? false;
    }

    /**
     * Keep the existing unique user/type row while archiving each completed year.
     * Rotate gateway references so old callbacks cannot settle the next year.
     */
    public function renewAnnualFeeIfDue(): bool
    {
        if (!$this->annualRenewalDue()) {
            return false;
        }

        return DB::transaction(function () {
            $fee = static::query()->whereKey($this->id)->lockForUpdate()->firstOrFail();
            if (!$fee->annualRenewalDue()) {
                $this->setRawAttributes($fee->getAttributes(), true);
                return false;
            }

            $metadata = $fee->metadata ?? [];
            $history = $metadata['annual_history'] ?? [];
            unset($metadata['annual_history']);
            $snapshot = $fee->getAttributes();
            $snapshot['metadata'] = $metadata;
            $snapshot['registration_expires_at'] = $fee->registration_expires_at->toIso8601String();
            $history[] = $snapshot;

            $fee->update([
                'amount' => self::PARTNER_ANNUAL_FEE,
                'currency' => 'PHP',
                'payment_status' => self::PAYMENT_UNPAID,
                'payment_date' => null,
                'waived_at' => null,
                'waived_by' => null,
                'waiver_reason' => null,
                'activated_at' => null,
                'is_active' => false,
                'paymongo_checkout_id' => null,
                'checkout_url' => null,
                'paymongo_reference' => 'reg-fee-'.$fee->user_id.'-merchant-'.Str::uuid(),
                'idempotency_key' => 'reg-fee-renewal-'.Str::uuid(),
                'failure_reason' => null,
                'metadata' => [
                    'annual_history' => $history,
                    'renewal_due_since' => $snapshot['registration_expires_at'],
                ],
            ]);
            // Preserve rejected/suspended partners and their approval decision.
            \App\Models\Partner::where('user_id', $fee->user_id)
                ->whereIn('status', ['active', 'approved'])
                ->update(['status' => 'pending']);
            $this->setRawAttributes($fee->getAttributes(), true);

            return true;
        });
    }
}
