<?php

namespace Tests\Feature;

use App\Models\Partner;
use App\Models\RegistrationFeePayment;
use App\Models\SecuritySetting;
use App\Models\User;
use App\Services\PaymentGatewayManager;
use App\Services\RegistrationFeeService;
use Mockery;
use Tests\TestCase;

class PartnerAnnualFeeTest extends TestCase
{
    private function merchant(): User
    {
        $user = User::factory()->create(['role' => 'partner_admin']);
        Partner::factory()->create(['user_id' => $user->id, 'status' => 'pending']);

        return $user;
    }

    public function test_merchant_fee_is_fixed_even_with_a_setting_or_amount_override(): void
    {
        SecuritySetting::setValue(RegistrationFeeService::SETTING_MERCHANT_FEE, '2500');
        $user = $this->merchant();
        $fee = RegistrationFeeService::ensurePaymentRecord($user, 'merchant', 50);
        $this->assertSame(1000.0, (float) $fee->amount);
        $this->assertSame(1000.0, RegistrationFeeService::getFeeForType('merchant'));
        $this->assertSame('annual', RegistrationFeeService::getStatusForUser($user)['billing_period']);
    }

    public function test_paid_year_expires_and_a_new_checkout_charges_exactly_one_thousand(): void
    {
        $user = $this->merchant();
        $fee = RegistrationFeeService::ensurePaymentRecord($user);
        $fee->update([
            'payment_status' => 'paid', 'payment_date' => now(),
            'application_status' => 'approved', 'is_active' => true,
            'paymongo_checkout_id' => 'cs_previous_year',
        ]);
        $oldReference = $fee->paymongo_reference;
        $expiry = $fee->registration_expires_at;
        $this->travelTo($expiry->copy()->subSecond());
        $this->assertTrue($fee->isFeeSatisfied());
        $this->travelTo($expiry);
        $status = RegistrationFeeService::getStatusForUser($user);
        $this->assertFalse($status['is_active']);
        $this->assertSame('unpaid', $status['payment_status']);
        $this->assertSame('approved', $status['application_status']);
        $this->assertCount(1, $fee->fresh()->metadata['annual_history']);
        $this->assertNull(RegistrationFeeService::handleWebhookSuccess('cs_previous_year', ['external_id' => $oldReference]));

        $gateway = Mockery::mock(PaymentGatewayManager::class);
        $gateway->shouldReceive('createInvoice')->once()
            ->withArgs(fn ($amount, $reference, $description, $options, $provider) =>
                $amount === 1000.0 && $reference !== $oldReference && $provider === 'paymongo'
                && str_contains($description, 'Annual'))
            ->andReturn(['id' => 'cs_new_year', 'invoice_url' => 'https://paymongo.test/new-year']);
        $this->app->instance(PaymentGatewayManager::class, $gateway);
        RegistrationFeeService::createCheckout($user);
        $paid = RegistrationFeeService::handleWebhookSuccess('cs_new_year');
        $this->assertTrue($paid->shouldBeActive());
        $this->assertSame(now()->addYearNoOverflow()->toDateString(), $paid->registration_expires_at->toDateString());
        $this->assertCount(1, $paid->metadata['annual_history']);
    }

    public function test_old_verification_checkout_is_rejected_after_renewal(): void
    {
        $user = $this->merchant();
        $fee = RegistrationFeeService::ensurePaymentRecord($user);
        $fee->update(['payment_status' => 'paid', 'payment_date' => now()->subYears(2), 'paymongo_checkout_id' => 'cs_old']);
        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('Checkout does not belong to the current registration period');
        RegistrationFeeService::verifyPayment($user, 'cs_old');
    }

    public function test_duplicate_paid_webhook_cannot_extend_expired_year(): void
    {
        $user = $this->merchant();
        $fee = RegistrationFeeService::ensurePaymentRecord($user);
        $paymentDate = now()->subYears(2)->startOfDay();
        $fee->update(['payment_status' => 'paid', 'payment_date' => $paymentDate, 'paymongo_checkout_id' => 'cs_expired']);
        $result = RegistrationFeeService::handleWebhookSuccess('cs_expired');
        $this->assertTrue($result->payment_date->equalTo($paymentDate));
        $this->assertFalse($result->isFeeSatisfied());
    }

    public function test_waived_year_renews_once_and_preserves_audit(): void
    {
        $user = $this->merchant();
        $admin = User::factory()->create(['role' => 'admin']);
        $fee = RegistrationFeeService::ensurePaymentRecord($user);
        $fee->update(['application_status' => 'approved']);
        $fee = RegistrationFeeService::waiveFee($fee, $admin, 'First year');
        $this->travelTo($fee->registration_expires_at);
        $renewed = RegistrationFeeService::waiveFee($fee, $admin, 'Renewal');
        $this->assertTrue($renewed->shouldBeActive());
        $this->assertSame('First year', $renewed->metadata['annual_history'][0]['waiver_reason']);
        $this->assertSame('Renewal', $renewed->waiver_reason);
        $this->assertSame($admin->id, $renewed->waived_by);
        $this->assertFalse($renewed->renewAnnualFeeIfDue());
    }

    public function test_leap_day_expires_on_february_28_and_rider_fees_stay_one_time(): void
    {
        $merchant = new RegistrationFeePayment([
            'account_type' => 'merchant', 'payment_status' => 'waived', 'waived_at' => '2024-02-29 12:00:00',
        ]);
        $this->assertSame('2025-02-28', $merchant->registration_expires_at->toDateString());
        $rider = new RegistrationFeePayment([
            'account_type' => 'rider', 'payment_status' => 'paid', 'payment_date' => now()->subYears(3),
        ]);
        $this->assertNull($rider->registration_expires_at);
        $this->assertTrue($rider->isFeeSatisfied());
    }
}
