<?php

namespace App\Services;

use App\Jobs\AutoAssignDriverJob;
use App\Jobs\NotifyNearbyDriversNewOrderJob;
use App\Models\Order;
use App\Models\SecuritySetting;

class OrderDispatchService
{
    /**
     * Publish an order to the driver network after its database transaction
     * commits. Both jobs independently re-check eligibility before acting.
     */
    public function publish(Order $order): void
    {
        if (! $order->isDispatchableToDrivers()) {
            return;
        }

        NotifyNearbyDriversNewOrderJob::dispatch($order)
            ->afterCommit()
            ->onQueue('notifications');

        if (SecuritySetting::getValue('driver.auto_assignment_enabled', true)) {
            AutoAssignDriverJob::dispatch($order)
                ->afterCommit()
                ->onQueue('driver-assignment');
        }
    }
}
