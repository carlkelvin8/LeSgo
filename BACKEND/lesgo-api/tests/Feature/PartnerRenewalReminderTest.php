<?php

namespace Tests\Feature;

use App\Jobs\SendPushNotificationJob;
use App\Models\Notification;
use App\Models\RegistrationFeePayment;
use App\Models\User;
use App\Services\RegistrationFeeService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Tests\TestCase;

class PartnerRenewalReminderTest extends TestCase
{
    use RefreshDatabase;

    /** Merchant whose annual renewal falls due $daysFromNow days from now. */
    private function merchantDueIn(int $daysFromNow, array $overrides = []): RegistrationFeePayment
    {
        $user = User::factory()->create(['role' => 'partner_admin']);

        return RegistrationFeePayment::create(array_merge([
            'user_id' => $user->id,
            'account_type' => RegistrationFeePayment::TYPE_MERCHANT,
            'amount' => RegistrationFeePayment::PARTNER_ANNUAL_FEE,
            'currency' => 'PHP',
            'payment_status' => RegistrationFeePayment::PAYMENT_PAID,
            'payment_date' => now()->subYear()->addDays($daysFromNow),
            'application_status' => RegistrationFeePayment::APP_APPROVED,
            'is_grandfathered' => false,
            'paymongo_reference' => 'reg-fee-test-'.$user->id,
            'idempotency_key' => 'reg-fee-test-'.$user->id,
        ], $overrides));
    }

    private function reminderCount(int $userId): int
    {
        return Notification::where('user_id', $userId)->where('type', 'partner_renewal_reminder')->count();
    }

    public function test_reminder_is_sent_once_when_renewal_is_within_thirty_days(): void
    {
        Bus::fake([SendPushNotificationJob::class]);
        $fee = $this->merchantDueIn(20);

        $this->artisan('registration-fees:remind-renewals')->assertSuccessful();
        $this->artisan('registration-fees:remind-renewals')->assertSuccessful();

        $this->assertSame(1, $this->reminderCount($fee->user_id));

        // Early payment is not possible (the fee reads "already paid" until it opens),
        // so the text must not tell merchants to renew beforehand.
        $body = Notification::where('user_id', $fee->user_id)->where('type', 'partner_renewal_reminder')->value('body');
        $this->assertStringContainsString('prepare the payment', $body);
        $this->assertStringNotContainsString('Renew before', $body);
    }

    public function test_no_reminder_when_renewal_is_more_than_thirty_days_away(): void
    {
        Bus::fake([SendPushNotificationJob::class]);
        $fee = $this->merchantDueIn(60);

        $this->artisan('registration-fees:remind-renewals')->assertSuccessful();

        $this->assertSame(0, $this->reminderCount($fee->user_id));
    }

    public function test_grandfathered_partner_gets_no_renewal_reminder(): void
    {
        Bus::fake([SendPushNotificationJob::class]);
        $fee = $this->merchantDueIn(10, ['is_grandfathered' => true]);

        $this->artisan('registration-fees:remind-renewals')->assertSuccessful();

        $this->assertSame(0, $this->reminderCount($fee->user_id));
    }

    public function test_reminder_fires_again_for_the_next_renewal_cycle(): void
    {
        Bus::fake([SendPushNotificationJob::class]);
        $fee = $this->merchantDueIn(20);
        $this->artisan('registration-fees:remind-renewals')->assertSuccessful();

        // Renewal cycle moves to a new due date that is again inside the window.
        $fee->update(['payment_date' => now()->subYear()->addDays(15)]);
        $this->artisan('registration-fees:remind-renewals')->assertSuccessful();

        $this->assertSame(2, $this->reminderCount($fee->user_id));
    }

    public function test_exemption_waives_unpaid_fee_and_stops_renewals(): void
    {
        $fee = $this->merchantDueIn(0, ['payment_status' => RegistrationFeePayment::PAYMENT_UNPAID, 'payment_date' => null,
            'activated_at' => now()->subYears(3)]);
        $admin = User::factory()->create(['role' => 'admin']);

        $updated = RegistrationFeeService::exemptFromAnnualRenewal($fee, $admin, 'Partner since 2022');

        $this->assertTrue($updated->is_grandfathered);
        $this->assertTrue($updated->isWaived());
        $this->assertNull($updated->registration_expires_at);
        $this->assertTrue($updated->isFeeSatisfied());
        $this->assertSame('Partner since 2022', $updated->metadata['renewal_exemption']['reason']);

        $this->artisan('registration-fees:renew-partners')->assertSuccessful();
        $this->assertSame(RegistrationFeePayment::PAYMENT_WAIVED, $fee->fresh()->payment_status);
    }

    public function test_exempting_a_paid_partner_past_their_renewal_keeps_them_satisfied(): void
    {
        $fee = $this->merchantDueIn(-40); // renewal already overdue
        $this->assertTrue($fee->fresh()->annualRenewalDue());
        $admin = User::factory()->create(['role' => 'admin']);

        $updated = RegistrationFeeService::exemptFromAnnualRenewal($fee, $admin);

        $this->assertFalse($updated->annualRenewalDue());
        $this->assertTrue($updated->isFeeSatisfied());
        $this->assertSame(RegistrationFeePayment::PAYMENT_PAID, $updated->payment_status);
    }

    public function test_rider_fee_cannot_be_exempted(): void
    {
        $user = User::factory()->create(['role' => 'driver']);
        $rider = RegistrationFeePayment::create([
            'user_id' => $user->id,
            'account_type' => RegistrationFeePayment::TYPE_RIDER,
            'amount' => 500,
            'currency' => 'PHP',
            'payment_status' => RegistrationFeePayment::PAYMENT_UNPAID,
            'application_status' => RegistrationFeePayment::APP_PENDING,
            'paymongo_reference' => 'reg-fee-rider-test',
            'idempotency_key' => 'reg-fee-rider-test',
        ]);

        $this->expectException(\DomainException::class);
        RegistrationFeeService::exemptFromAnnualRenewal($rider, User::factory()->create(['role' => 'admin']));
    }
}
