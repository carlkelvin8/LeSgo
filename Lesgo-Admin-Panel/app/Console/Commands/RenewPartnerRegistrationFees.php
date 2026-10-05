<?php

namespace App\Console\Commands;

use App\Models\RegistrationFeePayment;
use Illuminate\Console\Command;

class RenewPartnerRegistrationFees extends Command
{
    protected $signature = 'registration-fees:renew-partners';
    protected $description = 'Open annual partner renewals and preserve the completed fee history';

    public function handle(): int
    {
        $renewed = 0;
        RegistrationFeePayment::where('account_type', RegistrationFeePayment::TYPE_MERCHANT)
            ->where('is_grandfathered', false)
            ->whereIn('payment_status', ['paid', 'waived'])
            ->chunkById(200, function ($fees) use (&$renewed) {
                foreach ($fees as $fee) {
                    if ($fee->renewAnnualFeeIfDue()) {
                        $renewed++;
                    }
                }
            });
        $this->info("Opened {$renewed} annual partner renewals.");

        return self::SUCCESS;
    }
}

