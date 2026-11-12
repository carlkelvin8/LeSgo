<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Partner;
use App\Models\PartnerBranch;
use App\Models\Service;
use App\Models\User;
use App\Services\RegistrationFeeService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MerchantBranchTest extends TestCase
{
    use RefreshDatabase;

    private function merchant(): Partner
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'active', 'name' => 'Kape Co']);
        $fee = RegistrationFeeService::ensurePaymentRecord($owner);
        $fee->update(['payment_status' => 'waived', 'waived_at' => now(), 'application_status' => 'approved', 'is_active' => true]);

        return $partner;
    }

    private function branch(Partner $partner, array $attrs = []): PartnerBranch
    {
        return PartnerBranch::create(array_merge([
            'partner_id' => $partner->id,
            'name' => 'Main',
            'address_line1' => '1 Ayala Ave',
            'city' => 'Makati',
            'latitude' => 14.5547,
            'longitude' => 121.0244,
            'is_primary' => false,
            'is_open' => true,
        ], $attrs));
    }

    private function orderPayload(Partner $partner, array $extra = []): array
    {
        $service = Service::factory()->create(['code' => 'LESGO']);

        return array_merge([
            'service_id' => $service->id,
            'partner_id' => $partner->id,
            'pickup' => ['address' => 'Kape Co', 'lat' => 14.5547, 'lng' => 121.0244],
            'dropoff' => ['address' => '456 Mabini Ave', 'lat' => 14.6090, 'lng' => 121.0000],
            'estimated_distance_m' => 5000,
            'payment_method' => 'cash',
        ], $extra);
    }

    // ── Branch management ────────────────────────────────────────────────────

    public function test_owner_creates_branches_and_first_one_becomes_primary(): void
    {
        $partner = $this->merchant();
        Sanctum::actingAs($partner->user);

        $first = $this->postJson("/api/v1/partners/{$partner->id}/branches", [
            'name' => 'Makati', 'address_line1' => '1 Ayala Ave', 'latitude' => 14.55, 'longitude' => 121.02,
        ])->assertCreated()->assertJsonPath('data.is_primary', true)->json('data.id');

        $second = $this->postJson("/api/v1/partners/{$partner->id}/branches", [
            'name' => 'QC', 'address_line1' => 'Katipunan', 'latitude' => 14.64, 'longitude' => 121.07, 'is_primary' => true,
        ])->assertCreated()->assertJsonPath('data.is_primary', true)->json('data.id');

        $this->assertFalse(PartnerBranch::find($first)->is_primary);
        $this->assertTrue(PartnerBranch::find($second)->is_primary);
    }

    public function test_branch_requires_map_location(): void
    {
        $partner = $this->merchant();
        Sanctum::actingAs($partner->user);

        $this->postJson("/api/v1/partners/{$partner->id}/branches", [
            'name' => 'No pin', 'address_line1' => 'Somewhere',
        ])->assertStatus(422)->assertJsonValidationErrors(['latitude', 'longitude']);
    }

    public function test_other_merchant_cannot_create_edit_or_delete_branches(): void
    {
        $partner = $this->merchant();
        $branch = $this->branch($partner, ['is_primary' => true]);
        $this->branch($partner, ['name' => 'Second']);
        $intruder = $this->merchant();
        Sanctum::actingAs($intruder->user);

        $this->postJson("/api/v1/partners/{$partner->id}/branches", [
            'name' => 'Hijack', 'address_line1' => 'x', 'latitude' => 1, 'longitude' => 1,
        ])->assertForbidden();
        $this->patchJson("/api/v1/branches/{$branch->id}", ['name' => 'Hijacked'])->assertForbidden();
        $this->deleteJson("/api/v1/branches/{$branch->id}")->assertForbidden();

        $this->assertSame('Main', $branch->fresh()->name);
    }

    public function test_cannot_delete_last_branch_and_deleting_primary_promotes_another(): void
    {
        $partner = $this->merchant();
        $primary = $this->branch($partner, ['is_primary' => true]);
        Sanctum::actingAs($partner->user);

        $this->deleteJson("/api/v1/branches/{$primary->id}")->assertStatus(422);

        $other = $this->branch($partner, ['name' => 'Second']);
        $this->deleteJson("/api/v1/branches/{$primary->id}")->assertOk();
        $this->assertTrue($other->fresh()->is_primary);
    }

    public function test_cannot_delete_branch_with_active_orders(): void
    {
        $partner = $this->merchant();
        $this->branch($partner, ['is_primary' => true]);
        $busy = $this->branch($partner, ['name' => 'Busy']);
        Order::factory()->create(['partner_id' => $partner->id, 'partner_branch_id' => $busy->id, 'status' => 'pending']);
        Sanctum::actingAs($partner->user);

        $this->deleteJson("/api/v1/branches/{$busy->id}")->assertStatus(422);
    }

    public function test_owner_can_close_a_branch(): void
    {
        $partner = $this->merchant();
        $branch = $this->branch($partner, ['is_primary' => true]);
        Sanctum::actingAs($partner->user);

        $this->patchJson("/api/v1/branches/{$branch->id}", ['is_open' => false])
            ->assertOk()->assertJsonPath('data.is_open', false);
    }

    // ── Ordering from a branch ───────────────────────────────────────────────

    public function test_selected_branch_sets_pickup_point_and_is_recorded_on_order(): void
    {
        Queue::fake();
        $partner = $this->merchant();
        $this->branch($partner, ['is_primary' => true]);
        $qc = $this->branch($partner, [
            'name' => 'Katipunan', 'address_line1' => '300 Katipunan Ave', 'city' => 'Quezon City',
            'latitude' => 14.6392, 'longitude' => 121.0770, 'phone_number' => '09170000000',
        ]);
        $this->actingAsRole('customer');

        // Client sends stale pickup coordinates; the branch wins.
        $orderId = $this->postJson('/api/v1/orders', $this->orderPayload($partner, ['partner_branch_id' => $qc->id]))
            ->assertCreated()
            ->assertJsonPath('data.meta.branch.name', 'Katipunan')
            ->json('data.id');

        $order = Order::find($orderId);
        $this->assertSame($qc->id, $order->partner_branch_id);
        $this->assertEqualsWithDelta(14.6392, (float) $order->pickup_lat, 0.0001);
        $this->assertEqualsWithDelta(121.0770, (float) $order->pickup_lng, 0.0001);
        $this->assertSame('300 Katipunan Ave, Quezon City', $order->pickup_address);
        $this->assertSame('Kape Co – Katipunan', $order->pickup_contact_name);
        $this->assertSame('09170000000', $order->pickup_contact_phone);
    }

    public function test_branch_from_another_store_is_rejected(): void
    {
        Queue::fake();
        $partner = $this->merchant();
        $this->branch($partner, ['is_primary' => true]);
        $foreign = $this->branch($this->merchant(), ['is_primary' => true]);
        $this->actingAsRole('customer');

        $this->postJson('/api/v1/orders', $this->orderPayload($partner, ['partner_branch_id' => $foreign->id]))
            ->assertStatus(422);
    }

    public function test_closed_branch_is_rejected(): void
    {
        Queue::fake();
        $partner = $this->merchant();
        $closed = $this->branch($partner, ['is_primary' => true, 'is_open' => false]);
        $this->actingAsRole('customer');

        $this->postJson('/api/v1/orders', $this->orderPayload($partner, ['partner_branch_id' => $closed->id]))
            ->assertStatus(422);
    }

    public function test_older_clients_without_branch_get_primary_or_nearest_open_branch(): void
    {
        Queue::fake();
        $partner = $this->merchant();
        $primary = $this->branch($partner, ['is_primary' => true]);
        $this->actingAsRole('customer');

        $id = $this->postJson('/api/v1/orders', $this->orderPayload($partner))->assertCreated()->json('data.id');
        $this->assertSame($primary->id, Order::find($id)->partner_branch_id);

        $primary->update(['is_open' => false]);
        $near = $this->branch($partner, ['name' => 'Near drop-off', 'latitude' => 14.6085, 'longitude' => 121.0005]);
        $this->branch($partner, ['name' => 'Far', 'latitude' => 14.40, 'longitude' => 121.00]);

        $id = $this->postJson('/api/v1/orders', $this->orderPayload($partner))->assertCreated()->json('data.id');
        $this->assertSame($near->id, Order::find($id)->partner_branch_id);
    }

    public function test_merchant_can_filter_orders_by_branch(): void
    {
        $partner = $this->merchant();
        $a = $this->branch($partner, ['is_primary' => true]);
        $b = $this->branch($partner, ['name' => 'B']);
        Order::factory()->create(['partner_id' => $partner->id, 'partner_branch_id' => $a->id]);
        $orderB = Order::factory()->create(['partner_id' => $partner->id, 'partner_branch_id' => $b->id]);
        Sanctum::actingAs($partner->user);

        $ids = collect($this->getJson("/api/v1/orders?partner_branch_id={$b->id}")->assertOk()->json('data'))
            ->pluck('id')->all();
        $this->assertSame([$orderB->id], $ids);
    }

    public function test_expand_branches_lists_each_open_branch_as_its_own_store_card(): void
    {
        $partner = $this->merchant();
        $partner->update(['is_open' => true]);
        $main = $this->branch($partner, ['name' => 'Main', 'is_primary' => true]);
        $second = $this->branch($partner, [
            'name' => 'Urdaneta branch',
            'latitude' => 15.9761,
            'longitude' => 120.5711,
        ]);
        $this->branch($partner, ['name' => 'Closed branch', 'is_open' => false]);
        $customer = User::factory()->create();

        $default = $this->actingAs($customer, 'sanctum')->getJson('/api/v1/partners')
            ->assertOk()->json('data');
        $this->assertCount(1, $default);

        $listings = collect(
            $this->actingAs($customer, 'sanctum')
                ->getJson('/api/v1/partners?expand_branches=1')
                ->assertOk()->json('data')
        );

        $this->assertCount(2, $listings);
        $this->assertSame([$main->id, $second->id], $listings->pluck('branch_id')->all());
        $this->assertSame([$partner->id, $partner->id], $listings->pluck('id')->all());
        $this->assertSame('Kape Co – Urdaneta branch', $listings[1]['name']);
        $this->assertEquals(15.9761, $listings[1]['latitude']);
    }
}
