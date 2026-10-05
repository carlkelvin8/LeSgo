<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\RegistrationFeeService;
use App\Services\PaymentGatewayManager;
use App\Services\PayMongoService;
use Illuminate\Support\Facades\Http;
use Mockery;
use Tests\TestCase;

class RegistrationPaymentRecoveryTest extends TestCase
{
    public function test_pending_checkout_is_reused_without_another_gateway_request(): void
    {
        $user = User::factory()->create(['role' => 'driver']);
        $gateway = Mockery::mock(PaymentGatewayManager::class);
        $gateway->shouldReceive('createInvoice')->once()->andReturn([
            'id' => 'cs_saved', 'invoice_url' => 'https://checkout.test/saved']);
        $this->app->instance(PaymentGatewayManager::class, $gateway);
        $first = RegistrationFeeService::createCheckout($user);
        $second = RegistrationFeeService::createCheckout($user->fresh());
        $this->assertTrue($second['reused']);
        $this->assertSame($first['checkout_id'], $second['checkout_id']);
        $this->assertSame($first['checkout_url'], RegistrationFeeService::getStatusForUser($user)['checkout_url']);
    }

    public function test_gateway_timeout_preserves_reference_and_does_not_activate(): void
    {
        $user = User::factory()->create(['role' => 'driver']);
        $references = [];
        $gateway = Mockery::mock(PaymentGatewayManager::class);
        $gateway->shouldReceive('createInvoice')->twice()->andReturnUsing(function ($amount, $reference) use (&$references) {
            $references[] = $reference;
            throw new \RuntimeException('Timed out');
        });
        $this->app->instance(PaymentGatewayManager::class, $gateway);
        for ($attempt = 0; $attempt < 2; $attempt++) {
            try { RegistrationFeeService::createCheckout($user); $this->fail('Must report gateway failure'); }
            catch (\RuntimeException $e) { $this->assertSame('Timed out', $e->getMessage()); }
        }
        $this->assertSame($references[0], $references[1]);
        $this->assertFalse(RegistrationFeeService::canAccessOperationalFeatures($user));
    }

    public function test_expired_checkout_can_retry_and_foreign_checkout_cannot_be_verified(): void
    {
        $user = User::factory()->create(['role' => 'driver']);
        $record = RegistrationFeeService::ensurePaymentRecord($user);
        $oldReference = $record->paymongo_reference;
        $record->update(['payment_status' => 'pending', 'paymongo_checkout_id' => 'cs_old', 'checkout_url' => 'https://checkout.test/old']);
        $gateway = Mockery::mock(PaymentGatewayManager::class);
        $gateway->shouldReceive('getInvoice')->with('cs_old', 'paymongo')->twice()->andReturn(['payment_status' => 'expired']);
        $gateway->shouldReceive('createInvoice')->once()->andReturn(['id' => 'cs_new', 'invoice_url' => 'https://checkout.test/new']);
        $this->app->instance(PaymentGatewayManager::class, $gateway);
        $this->assertSame('expired', RegistrationFeeService::verifyPayment($user)->payment_status);
        $next = RegistrationFeeService::createCheckout($user);
        $this->assertFalse($next['reused']);
        $this->assertNotSame($oldReference, $next['paymongo_reference']);
        $this->expectException(\RuntimeException::class);
        RegistrationFeeService::verifyPayment($user, 'cs_foreign');
    }

    public function test_failed_attempt_in_active_checkout_cannot_create_a_duplicate_session(): void
    {
        $user = User::factory()->create(['role' => 'driver']);
        $record = RegistrationFeeService::ensurePaymentRecord($user);
        $record->update(['payment_status' => 'failed', 'paymongo_checkout_id' => 'cs_active', 'checkout_url' => 'https://checkout.test/active']);
        $gateway = Mockery::mock(PaymentGatewayManager::class);
        $gateway->shouldReceive('getInvoice')->with('cs_active', 'paymongo')->once()->andReturn(['payment_status' => 'pending']);
        $gateway->shouldNotReceive('createInvoice');
        $this->app->instance(PaymentGatewayManager::class, $gateway);
        $this->assertTrue(RegistrationFeeService::createCheckout($user)['reused']);
        $this->assertSame('pending', $record->fresh()->payment_status);
    }

    public function test_retry_during_gateway_outage_keeps_the_original_checkout(): void
    {
        $user = User::factory()->create(['role' => 'driver']);
        $record = RegistrationFeeService::ensurePaymentRecord($user);
        $record->update(['payment_status' => 'failed', 'paymongo_checkout_id' => 'cs_uncertain', 'checkout_url' => 'https://checkout.test/saved']);
        $gateway = Mockery::mock(PaymentGatewayManager::class);
        $gateway->shouldReceive('getInvoice')->once()->andThrow(new \RuntimeException('Gateway unavailable'));
        $gateway->shouldNotReceive('createInvoice');
        $this->app->instance(PaymentGatewayManager::class, $gateway);
        try {
            RegistrationFeeService::createCheckout($user);
            $this->fail('Must report uncertainty');
        } catch (\RuntimeException $e) {
            $this->assertSame('Gateway unavailable', $e->getMessage());
        }
        $this->assertSame('cs_uncertain', $record->fresh()->paymongo_checkout_id);
    }

    public function test_gateway_parser_prioritizes_later_paid_attempt_and_resolves_expiry(): void
    {
        Http::fake(['api.paymongo.com/v1/checkout_sessions/*' => Http::sequence()
            ->push(['data' => ['attributes' => ['status' => 'active', 'payments' => [
                ['attributes' => ['status' => 'failed']], ['attributes' => ['status' => 'paid']],
            ]]]])
            ->push(['data' => ['attributes' => ['status' => 'expired', 'payments' => []]]])
            ->push(['data' => ['attributes' => ['status' => 'active', 'payments' => [
                ['attributes' => ['status' => 'failed']],
            ]]]])]);
        $gateway = new PayMongoService;
        $this->assertSame('paid', $gateway->getCheckoutSession('cs_paid')['payment_status']);
        $this->assertSame('expired', $gateway->getCheckoutSession('cs_expired')['payment_status']);
        $this->assertSame('pending', $gateway->getCheckoutSession('cs_retry')['payment_status']);
    }

    public function test_successful_referral_api_uses_approved_brand(): void
    {
        $user = User::factory()->create(['role' => 'customer', 'referral_code' => 'TESTCODE']);
        $this->actingAs($user, 'sanctum')->postJson('/api/v1/social/referral/share', ['platform' => 'facebook'])
            ->assertSuccessful()->assertJsonPath('data.share_title', 'Join LeSgo using my referral code!')
            ->assertJsonPath('data.share_description', 'Sign up on LeSgo and use my referral code: TESTCODE to get bonuses! 🎁')
            ->assertJsonPath('data.share_url', 'https://play.google.com/store/apps/details?id=com.lesgo_customer');
    }
}
