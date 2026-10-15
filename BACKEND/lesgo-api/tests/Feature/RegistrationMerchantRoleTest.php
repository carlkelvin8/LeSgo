<?php

namespace Tests\Feature;

use App\Models\Partner;
use App\Models\User;
use App\Services\PaymentGatewayManager;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Mockery;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class RegistrationMerchantRoleTest extends TestCase
{
    use RefreshDatabase;

    public static function legacyRoles(): array
    {
        return [['partner'], ['merchant']];
    }

    #[DataProvider('legacyRoles')]
    public function test_legacy_merchant_owner_can_create_checkout_without_becoming_active(string $role): void
    {
        $user = User::factory()->create(['role' => $role]);
        Partner::factory()->create(['user_id' => $user->id, 'status' => 'pending']);
        Sanctum::actingAs($user);
        $gateway = Mockery::mock(PaymentGatewayManager::class);
        $gateway->shouldReceive('createInvoice')->once()->andReturn([
            'id' => 'cs_legacy', 'invoice_url' => 'https://checkout.example.test/legacy',
        ]);
        $this->app->instance(PaymentGatewayManager::class, $gateway);

        $this->getJson('/api/v1/registration-fee/status')->assertOk()
            ->assertJsonPath('data.requires_fee', true)
            ->assertJsonPath('data.is_active', false);
        $this->postJson('/api/v1/registration-fee/checkout')->assertOk()
            ->assertJsonPath('data.checkout_id', 'cs_legacy');
        $this->getJson('/api/v1/registration-fee/status')->assertOk()
            ->assertJsonPath('data.payment_status', 'pending')
            ->assertJsonPath('data.can_access_operational_features', false);
    }

    #[DataProvider('legacyRoles')]
    public function test_auth_profile_includes_legacy_owner_registration_status(string $role): void
    {
        $user = User::factory()->create(['role' => $role]);
        Partner::factory()->create(['user_id' => $user->id, 'status' => 'pending']);
        Sanctum::actingAs($user);

        $this->getJson('/api/v1/auth/me')->assertOk()
            ->assertJsonPath('user.registration_fee.requires_fee', true)
            ->assertJsonPath('user.registration_fee.is_active', false);
    }

    #[DataProvider('legacyRoles')]
    public function test_legacy_role_without_owned_merchant_cannot_start_checkout(string $role): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => $role]));
        $this->postJson('/api/v1/registration-fee/checkout')->assertUnprocessable();
        $this->assertDatabaseCount('registration_fee_payments', 0);
    }

    public function test_customer_with_partner_record_cannot_start_merchant_checkout(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        Partner::factory()->create(['user_id' => $user->id]);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/registration-fee/checkout')->assertUnprocessable();
        $this->assertDatabaseCount('registration_fee_payments', 0);
    }
}
