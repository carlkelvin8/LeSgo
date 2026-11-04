<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Partner;
use App\Models\PartnerStaff;
use App\Models\Service;
use App\Models\User;
use App\Services\RegistrationFeeService;
use Tests\TestCase;

/**
 * Staff work the store's orders. The order access check read a users.partner_id
 * that does not exist, so every staff request was a silent 403.
 */
class PartnerStaffOrderAccessTest extends TestCase
{
    private function merchant(): Partner
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'active', 'is_open' => true]);
        $fee = RegistrationFeeService::ensurePaymentRecord($owner);
        $fee->update(['payment_status' => 'waived', 'waived_at' => now(), 'application_status' => 'approved', 'is_active' => true]);

        return $partner;
    }

    private function orderFor(Partner $partner): Order
    {
        return Order::factory()->create([
            'partner_id' => $partner->id,
            'service_id' => Service::factory()->create(['code' => 'LESEAT'])->id,
            'status' => 'pending',
        ]);
    }

    private function staffFor(Partner $partner, bool $active = true): User
    {
        $staff = User::factory()->create(['role' => 'partner_staff']);
        PartnerStaff::create(['partner_id' => $partner->id, 'user_id' => $staff->id, 'role' => 'cook', 'is_active' => $active]);

        return $staff;
    }

    public function test_active_staff_can_view_their_stores_order_but_not_another_stores(): void
    {
        $partner = $this->merchant();
        $staff = $this->staffFor($partner);

        $this->actingAs($staff, 'sanctum')
            ->getJson("/api/v1/orders/{$this->orderFor($partner)->id}")->assertOk();
        $this->actingAs($staff, 'sanctum')
            ->getJson("/api/v1/orders/{$this->orderFor($this->merchant())->id}")->assertForbidden();
    }

    public function test_deactivated_staff_lose_access(): void
    {
        $partner = $this->merchant();

        $this->actingAs($this->staffFor($partner, active: false), 'sanctum')
            ->getJson("/api/v1/orders/{$this->orderFor($partner)->id}")->assertForbidden();
    }

    public function test_working_partner_id_covers_owner_staff_and_everyone_else(): void
    {
        $partner = $this->merchant();

        $this->assertSame($partner->id, $partner->user->workingPartnerId());
        $this->assertSame($partner->id, $this->staffFor($partner)->workingPartnerId());
        $this->assertNull($this->staffFor($partner, active: false)->workingPartnerId());
        $this->assertNull(User::factory()->create(['role' => 'customer'])->workingPartnerId());
    }
}
