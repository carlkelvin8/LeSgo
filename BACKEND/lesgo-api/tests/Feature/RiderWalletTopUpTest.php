<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTopUp;
use App\Models\WalletTransaction;
use App\Services\PaymentGatewayManager;
use Mockery;
use Tests\TestCase;

class RiderWalletTopUpTest extends TestCase
{
    public function test_paid_rider_topup_reflects_in_lespay_exactly_once(): void
    {
        $rider = User::factory()->driver()->create();
        \App\Models\DriverProfile::factory()->create(['user_id' => $rider->id]);
        $this->activatePartner($rider);
        $wallet = Wallet::factory()->create(['user_id' => $rider->id, 'balance' => 50]);
        $topUp = WalletTopUp::create([
            'user_id' => $rider->id,
            'wallet_id' => $wallet->id,
            'amount' => 100,
            'fee' => 1.5,
            'total_charged' => 101.5,
            'currency' => 'PHP',
            'status' => 'pending',
            'payment_method' => 'paymongo',
            'provider' => 'paymongo',
            'gateway_reference' => 'rider-checkout',
            'external_id' => 'rider-topup-test',
        ]);
        $gateway = Mockery::mock(PaymentGatewayManager::class);
        $gateway->shouldReceive('getInvoice')->once()
            ->with('rider-checkout', 'paymongo')->andReturn(['status' => 'PAID']);
        $gateway->shouldReceive('normalizeInvoiceStatus')->once()->andReturn('paid');
        $this->app->instance(PaymentGatewayManager::class, $gateway);

        $this->actingAs($rider, 'sanctum');
        for ($attempt = 0; $attempt < 2; $attempt++) {
            $response = $this->postJson('/api/v1/wallets/my/topup', [
                'gateway_reference' => 'rider-checkout',
            ])->assertOk()->assertJsonPath('success', true);
            $this->assertEquals(150, $response->json('data.balance'));
        }

        $response = $this->getJson('/api/v1/wallets/my/wallet')->assertOk();
        $this->assertEquals(150, $response->json('data.balance'));
        $this->assertSame('paid', $topUp->fresh()->status);
        $this->assertSame(1, WalletTransaction::where('wallet_id', $wallet->id)->count());
    }
}
