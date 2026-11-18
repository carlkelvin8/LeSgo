<?php

namespace App\Console\Commands;

use App\Models\RegistrationFeePayment;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class RemindPartnerRenewals extends Command
{
    public const REMINDER_WINDOW_DAYS = 30;

    protected $signature = 'registration-fees:remind-renewals';
    protected $description = 'Notify merchant partners 30 days before their annual renewal is due (once per renewal cycle)';

    public function handle(): int
    {
        $sent = 0;
        $now = now();
        $horizon = now()->addDays(self::REMINDER_WINDOW_DAYS);

        RegistrationFeePayment::where('account_type', RegistrationFeePayment::TYPE_MERCHANT)
            ->where('is_grandfathered', false)
            ->whereIn('payment_status', ['paid', 'waived'])
            ->chunkById(200, function ($fees) use (&$sent, $now, $horizon) {
                foreach ($fees as $fee) {
                    if ($this->remindIfDueSoon($fee, $now, $horizon)) {
                        $sent++;
                    }
                }
            });

        $this->info("Sent {$sent} annual renewal reminders.");

        return self::SUCCESS;
    }

    private function remindIfDueSoon(RegistrationFeePayment $fee, Carbon $now, Carbon $horizon): bool
    {
        $expiresAt = $fee->registration_expires_at;
        if (!$expiresAt || $expiresAt->lte($now) || $expiresAt->gt($horizon)) {
            return false;
        }

        $cycle = $expiresAt->toIso8601String();

        return DB::transaction(function () use ($fee, $cycle, $expiresAt) {
            // Re-check under lock: one reminder per renewal cycle, even if runs overlap or retry.
            $locked = RegistrationFeePayment::whereKey($fee->id)->lockForUpdate()->firstOrFail();
            if (($locked->metadata['renewal_reminder_for'] ?? null) === $cycle) {
                return false;
            }

            $locked->update([
                'metadata' => array_merge($locked->metadata ?? [], ['renewal_reminder_for' => $cycle]),
            ]);

            NotificationService::send(
                $locked->user_id,
                'partner_renewal_reminder',
                'Annual partner renewal due soon',
                'Your annual LeSgo partner renewal of ₱'.number_format(RegistrationFeePayment::PARTNER_ANNUAL_FEE, 2)
                    .' is due on '.$expiresAt->format('M d, Y').'. Renew before then to keep your shop open.',
                ['type' => 'partner_renewal_reminder', 'due_at' => $cycle],
                'all'
            );

            return true;
        });
    }
}
