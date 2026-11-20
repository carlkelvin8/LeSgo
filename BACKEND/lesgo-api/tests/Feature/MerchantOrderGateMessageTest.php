<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Partner;
use App\Models\Service;
use App\Models\User;
use App\Services\RegistrationFeeService;
use Tests\TestCase;

/**
 * A merchant who has not been approved / has not paid the registration fee
 * cannot accept orders. The app must be told why, not just "not allowed".
 */
class MerchantOrderGateMessageTest extends TestCase
{
    private function pendingOrder(Partner $partner): Order
    {
        $service = Service::factory()->create(['code' => 'LESEAT']);

        return Order::factory()->create([
            'service_id' => $service->id,
            'partner_id' => $partner->id,
            'status' => 'pending',
        ]);
    }

    public function test_unapproved_merchant_gets_a_clear_reason_when_accepting_is_blocked(): void
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'pending']);
        RegistrationFeeService::ensurePaymentRecord($owner);
        $order = $this->pendingOrder($partner);

        $this->actingAs($owner, 'sanctum')
            ->patchJson("/api/v1/orders/{$order->id}/status", ['status' => 'searching_driver'])
            ->assertForbidden()
            ->assertJsonPath('message', 'Restricted – Payment and Approval Required');
    }

    public function test_approved_merchant_can_still_accept_the_order(): void
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'active']);
        $fee = RegistrationFeeService::ensurePaymentRecord($owner);
        $fee->update(['payment_status' => 'waived', 'waived_at' => now(), 'application_status' => 'approved', 'is_active' => true]);
        $order = $this->pendingOrder($partner);

        $this->actingAs($owner, 'sanctum')
            ->patchJson("/api/v1/orders/{$order->id}/status", ['status' => 'searching_driver'])
            ->assertOk();
    }
}
