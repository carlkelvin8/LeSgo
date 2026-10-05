<?php

namespace Tests\Feature;

use App\Models\Partner;
use App\Models\RegistrationFeePayment;
use App\Models\User;
use App\Services\RegistrationFeeService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PartnerAnnualFeeTest extends TestCase
{
    use RefreshDatabase;

    private function partner(): Partner
    {
        return Partner::create([
            'user_id' => User::factory()->create(['role' => 'partner'])->id,
            'name' => 'Annual Test Partner',
            'slug' => 'annual-test-partner',
            'status' => 'pending',
        ]);
    }

    private function admin(): User
    {
        return User::factory()->create(['role' => 'admin', 'admin_role' => 'super_admin', 'is_active' => true]);
    }

    public function test_partner_page_creates_fixed_fee_and_shows_waive_button(): void
    {
        config(['app.key' => 'base64:'.base64_encode(str_repeat('a', 32))]);
        $this->withoutVite();
        $partner = $this->partner();
        $this->actingAs($this->admin())->get(route('admin.partners.show', $partner))
            ->assertOk()->assertSee('₱1,000 per year')->assertSee('Waive &amp; Activate', false);
        $this->assertDatabaseHas('registration_fee_payments', [
            'user_id' => $partner->user_id, 'account_type' => 'merchant',
            'amount' => 1000, 'payment_status' => 'unpaid',
        ]);
    }

    public function test_waiver_activates_partner_for_one_year_and_keeps_original_audit_on_retry(): void
    {
        config(['app.key' => 'base64:'.base64_encode(str_repeat('a', 32))]);
        $this->travelTo(now()->setDate(2026, 9, 15)->startOfDay());
        $partner = $this->partner();
        $fee = RegistrationFeeService::ensureMerchantFee($partner->user);
        $admin = $this->admin();
        $this->actingAs($admin)->post(route('admin.registration-fees.waive', $fee), ['reason' => 'Launch promotion'])
            ->assertSessionHas('success');
        $fee->refresh();
        $this->assertTrue($fee->shouldBeActive());
        $this->assertSame('active', $partner->fresh()->status);
        $this->assertSame('2027-09-15', $fee->registration_expires_at->toDateString());
        $this->travel(1)->days();
        RegistrationFeeService::waiveAndApprove($fee, $admin, 'Duplicate request');
        $this->assertSame('Launch promotion', $fee->fresh()->waiver_reason);
        $this->assertSame('2027-09-15', $fee->fresh()->registration_expires_at->toDateString());
    }

    public function test_expired_waiver_is_archived_and_next_year_can_be_waived(): void
    {
        $partner = $this->partner();
        $admin = $this->admin();
        $fee = RegistrationFeeService::waiveAndApprove(RegistrationFeeService::ensureMerchantFee($partner->user), $admin, 'First year');
        $oldReference = $fee->paymongo_reference;
        $this->travelTo($fee->registration_expires_at);
        $this->assertFalse($fee->isFeeSatisfied());
        $this->artisan('registration-fees:renew-partners')->assertSuccessful();
        $fee->refresh();
        $this->assertSame('unpaid', $fee->payment_status);
        $this->assertSame('approved', $fee->application_status);
        $this->assertSame('pending', $partner->fresh()->status);
        $this->assertSame(1000.0, (float) $fee->amount);
        $this->assertNotSame($oldReference, $fee->paymongo_reference);
        $this->assertSame('First year', $fee->metadata['annual_history'][0]['waiver_reason']);
        $this->artisan('registration-fees:renew-partners')->assertSuccessful();
        $this->assertCount(1, $fee->fresh()->metadata['annual_history']);
        $renewed = RegistrationFeeService::waiveAndApprove($fee, $admin, 'Second year');
        $this->assertTrue($renewed->shouldBeActive());
        $this->assertCount(1, $renewed->metadata['annual_history']);
        config(['app.key' => 'base64:'.base64_encode(str_repeat('a', 32))]);
        $this->withoutVite();
        $this->actingAs($admin)->get(route('admin.registration-fees.show', $fee))
            ->assertOk()->assertSee('Annual fee history')->assertSee('First year');
    }

    public function test_paid_current_year_cannot_be_overwritten_with_waiver(): void
    {
        $partner = $this->partner();
        $fee = RegistrationFeeService::ensureMerchantFee($partner->user);
        $fee->update(['payment_status' => 'paid', 'payment_date' => now()]);
        $this->expectException(\DomainException::class);
        RegistrationFeeService::waiveAndApprove($fee, $this->admin(), 'Must fail');
    }

    public function test_non_admin_cannot_waive_partner_fee(): void
    {
        config(['app.key' => 'base64:'.base64_encode(str_repeat('a', 32))]);
        $partner = $this->partner();
        $fee = RegistrationFeeService::ensureMerchantFee($partner->user);
        $this->actingAs($partner->user)->post(route('admin.registration-fees.waive', $fee))
            ->assertForbidden();
        $this->assertSame('unpaid', $fee->fresh()->payment_status);
    }
}
