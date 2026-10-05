<?php

namespace Tests\Feature;

use App\Models\RegistrationFeePayment;
use App\Models\User;
use App\Models\DriverProfile;
use App\Models\Partner;
use App\Services\RegistrationFeeService;
use App\Services\PaymentGatewayManager;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Mockery;

class RegistrationFeePayMongoTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.paymongo.secret_key' => 'sk_test_dummy']);
        \App\Models\SecuritySetting::updateOrCreate(
            ['setting_key' => RegistrationFeeService::SETTING_RIDER_FEE],
            ['setting_value' => '500.00', 'data_type' => 'string', 'description' => 'test', 'category' => 'registration']
        );
        \App\Models\SecuritySetting::updateOrCreate(
            ['setting_key' => RegistrationFeeService::SETTING_MERCHANT_FEE],
            ['setting_value' => '1000.00', 'data_type' => 'string', 'description' => 'test', 'category' => 'registration']
        );
        \App\Models\SecuritySetting::updateOrCreate(
            ['setting_key' => RegistrationFeeService::SETTING_ENFORCE_FROM],
            ['setting_value' => now()->toDateString(), 'data_type' => 'string', 'description' => 'test', 'category' => 'registration']
        );
    }

    public function test_rider_full_flow_paid_plus_approved_active(): void
    {
        // Register rider (simulated via service)
        $user = User::factory()->create(['role' => 'driver', 'created_at' => now()]);
        $profile = DriverProfile::factory()->create(['user_id' => $user->id, 'status' => 'pending']);
        $user->load('driverProfile');

        // Initial status: Restricted (unpaid + pending)
        $status = RegistrationFeeService::getStatusForUser($user);
        $this->assertFalse($status['is_active']);
        $this->assertEquals('unpaid', $status['payment_status']);
        $this->assertEquals('pending', $status['application_status']);

        // Create checkout
        $mock = Mockery::mock(PaymentGatewayManager::class);
        $mock->shouldReceive('createInvoice')->once()->andReturn([
            'id' => 'cs_test_rider_123',
            'invoice_url' => 'https://paymongo.test/checkout/cs_test_rider_123',
            'status' => 'pending',
        ]);
        $this->app->instance(PaymentGatewayManager::class, $mock);
        $checkout = RegistrationFeeService::createCheckout($user);
        $this->assertEquals('cs_test_rider_123', $checkout['checkout_id']);
        $this->assertEquals('pending', $checkout['payment']->payment_status);

        // Webhook confirms payment
        $paid = RegistrationFeeService::handleWebhookSuccess('cs_test_rider_123', ['id' => 'cs_test_rider_123', 'external_id' => $checkout['paymongo_reference'], 'status' => 'PAID']);
        $this->assertEquals('paid', $paid->payment_status);
        // Still restricted because application pending
        $this->assertFalse($paid->is_active);
        $afterPay = RegistrationFeeService::getStatusForUser($user);
        $this->assertEquals('Payment Successful – Application Pending Approval', $afterPay['display_status']);
        $this->assertFalse($afterPay['is_active']);

        // Admin approves
        $admin = User::factory()->create(['role' => 'admin']);
        $approved = RegistrationFeeService::approveApplication($paid->fresh(), $admin);
        $this->assertTrue($approved->is_active);
        $this->assertTrue($approved->shouldBeActive());
        $this->assertEquals('approved', $approved->application_status);
        // Driver profile should now be active
        $this->assertEquals('active', $profile->fresh()->status);

        // Can now access operational features
        $this->assertTrue(RegistrationFeeService::canAccessOperationalFeatures($user));
    }

    public function test_rider_registration_fee_uses_the_selected_package_price(): void
    {
        $expectations = [
            'basic' => 999.00,
            'advance' => 1999.00,
            'pro' => 2999.00,
        ];

        foreach ($expectations as $tier => $expectedPrice) {
            $user = User::factory()->create(['role' => 'driver', 'created_at' => now()]);
            DriverProfile::factory()->create([
                'user_id' => $user->id,
                'status' => 'pending',
                'package_tier' => $tier,
            ]);

            $payment = RegistrationFeeService::ensurePaymentRecord($user);

            $this->assertSame($expectedPrice, (float) $payment->amount, $tier);
        }
    }

    public function test_restricted_combinations(): void
    {
        $user = User::factory()->create(['role' => 'driver', 'created_at' => now()]);
        DriverProfile::factory()->create(['user_id' => $user->id, 'status' => 'pending']);
        $payment = RegistrationFeeService::ensurePaymentRecord($user);

        // Unpaid + pending => Restricted
        $this->assertFalse(RegistrationFeeService::canAccessOperationalFeatures($user));

        // Paid + pending => Restricted
        $payment->update(['payment_status' => 'paid', 'payment_date' => now()]);
        RegistrationFeeService::tryActivate($payment->fresh());
        $this->assertFalse(RegistrationFeeService::canAccessOperationalFeatures($user));

        // Reset to unpaid + approved => Restricted
        $payment->update(['payment_status' => 'unpaid', 'application_status' => 'approved', 'approved_at' => now(), 'is_active' => false, 'activated_at' => null]);
        $this->assertFalse(RegistrationFeeService::canAccessOperationalFeatures($user));

        // Paid + approved => Active
        $payment->update(['payment_status' => 'paid', 'application_status' => 'approved']);
        RegistrationFeeService::tryActivate($payment->fresh());
        $this->assertTrue(RegistrationFeeService::canAccessOperationalFeatures($user));

        // Rejected => Restricted even if paid
        $admin = User::factory()->create(['role' => 'admin']);
        RegistrationFeeService::rejectApplication($payment->fresh(), $admin);
        $this->assertFalse(RegistrationFeeService::canAccessOperationalFeatures($user));
    }

    public function test_admin_approval_does_not_bypass_unpaid(): void
    {
        $user = User::factory()->create(['role' => 'driver', 'created_at' => now()]);
        DriverProfile::factory()->create(['user_id' => $user->id, 'status' => 'pending']);
        $payment = RegistrationFeeService::ensurePaymentRecord($user);
        $admin = User::factory()->create(['role' => 'admin']);

        // Try to approve while unpaid
        $approved = RegistrationFeeService::approveApplication($payment, $admin);
        $this->assertEquals('approved', $approved->application_status);
        $this->assertFalse($approved->is_active); // must remain restricted
        $freshProfile = DriverProfile::where('user_id', $user->id)->first();
        $this->assertEquals('pending', $freshProfile->status);
    }

    public function test_merchant_flow(): void
    {
        $user = User::factory()->create(['role' => 'partner_admin', 'created_at' => now()]);
        $partner = Partner::factory()->create(['user_id' => $user->id, 'status' => 'pending', 'is_open' => false]);
        $payment = RegistrationFeeService::ensurePaymentRecord($user);
        $this->assertEquals('merchant', $payment->account_type);
        $this->assertEquals(1000.00, (float) $payment->amount);
        $this->assertFalse($payment->is_active);

        // Simulate paid webhook
        $payment->update(['payment_status' => 'paid', 'payment_date' => now()]);
        RegistrationFeeService::tryActivate($payment->fresh());
        $this->assertFalse(RegistrationFeeService::canAccessOperationalFeatures($user)); // pending approval

        $admin = User::factory()->create(['role' => 'admin']);
        RegistrationFeeService::approveApplication($payment->fresh(), $admin);
        $this->assertTrue(RegistrationFeeService::canAccessOperationalFeatures($user));
        $this->assertEquals('active', $partner->fresh()->status);
    }

    public function test_webhook_idempotent(): void
    {
        $user = User::factory()->create(['role' => 'driver', 'created_at' => now()]);
        DriverProfile::factory()->create(['user_id' => $user->id, 'status' => 'pending']);
        $payment = RegistrationFeeService::ensurePaymentRecord($user);
        $mock = Mockery::mock(PaymentGatewayManager::class);
        $mock->shouldReceive('createInvoice')->andReturn(['id' => 'cs_dup', 'invoice_url' => 'https://x', 'status' => 'pending']);
        $this->app->instance(PaymentGatewayManager::class, $mock);
        RegistrationFeeService::createCheckout($user);

        RegistrationFeeService::handleWebhookSuccess('cs_dup', ['id' => 'cs_dup']);
        $first = RegistrationFeePayment::find($payment->id);
        $this->assertEquals('paid', $first->payment_status);

        // Duplicate webhook
        RegistrationFeeService::handleWebhookSuccess('cs_dup', ['id' => 'cs_dup']);
        $second = RegistrationFeePayment::find($payment->id);
        $this->assertEquals('paid', $second->payment_status);
        $this->assertEquals($first->payment_date->toDateTimeString(), $second->payment_date->toDateTimeString());
    }

    public function test_existing_active_profile_does_not_bypass_unpaid_fee(): void
    {
        // Simulate old user created before enforce_from
        \App\Models\SecuritySetting::setValue(RegistrationFeeService::SETTING_ENFORCE_FROM, now()->addDay()->toDateString());
        $oldUser = User::factory()->create(['role' => 'driver', 'created_at' => now()->subDays(10)]);
        $oldProfile = DriverProfile::factory()->create(['user_id' => $oldUser->id, 'status' => 'active']);
        $status = RegistrationFeeService::getStatusForUser($oldUser);
        $this->assertFalse($status['is_active']);
        $this->assertFalse($status['is_grandfathered'] ?? false);
        $this->assertEquals('unpaid', $status['payment_status']);
        $this->assertFalse(RegistrationFeeService::canAccessOperationalFeatures($oldUser));
    }
}
