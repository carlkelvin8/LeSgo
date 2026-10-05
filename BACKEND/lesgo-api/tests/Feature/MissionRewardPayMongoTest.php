<?php

namespace Tests\Feature;

use App\Models\DriverMission;
use App\Models\DriverProfile;
use App\Models\MissionRewardPayout;
use App\Models\MissionTemplate;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletLinkedAccount;
use App\Services\MissionRewardPayoutService;
use App\Services\PaymentGatewayManager;
use App\Services\PayMongoService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;
use Mockery;

class MissionRewardPayMongoTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Ensure PayMongo is considered configured for tests
        config(['services.paymongo.secret_key' => 'sk_test_dummy']);
        config(['services.paymongo.wallet_account_number' => '09170000000']);
        config(['services.paymongo.wallet_account_name' => 'LeSGo Platform']);
    }

    private function createDriverWithMission(float $reward = 150.00): array
    {
        $user = User::factory()->create(['role' => 'driver', 'is_active' => true]);
        $profile = DriverProfile::factory()->create(['user_id' => $user->id]);
        $wallet = Wallet::create(['user_id' => $user->id, 'balance' => 0, 'currency' => 'PHP']);

        $template = MissionTemplate::create([
            'title' => 'Complete 5 orders',
            'description' => 'Test mission',
            'type' => 'daily',
            'target_audience' => 'driver',
            'goal_type' => 'complete_orders',
            'goal_target' => 5,
            'reward_amount' => $reward,
            'reward_currency' => 'PHP',
            'is_active' => true,
        ]);

        $mission = DriverMission::create([
            'driver_profile_id' => $profile->id,
            'mission_template_id' => $template->id,
            'current_progress' => 5,
            'goal_target' => 5,
            'is_completed' => true,
            'completed_at' => now(),
            'reward_claimed' => false,
            'mission_date' => now()->toDateString(),
        ]);

        // Create linked GCash for payout
        WalletLinkedAccount::create([
            'user_id' => $user->id,
            'provider' => 'gcash',
            'account_label' => 'GCash',
            'account_last4' => '0000',
            'is_verified' => true,
            'meta' => [
                'account_number' => '09171234567',
                'account_holder_name' => $user->name,
            ],
        ]);

        return compact('user', 'profile', 'wallet', 'template', 'mission');
    }

    public function test_end_to_end_mission_reward_flow(): void
    {
        $data = $this->createDriverWithMission(200.00);
        $user = $data['user'];
        $mission = $data['mission'];
        $template = $data['template'];

        // 1. Mission Completed — already is_completed true
        $this->assertTrue($mission->is_completed);

        // 2. Reward Validated — validateAndCreatePayout checks 4 conditions
        $payout = MissionRewardPayoutService::validateAndCreatePayout($mission, $user);
        $this->assertEquals(MissionRewardPayout::STATUS_PENDING, $payout->status);
        $this->assertEquals($user->id, $payout->rider_user_id);
        $this->assertEquals($mission->id, $payout->mission_id);
        $this->assertEquals(200.00, (float) $payout->reward_amount);
        $this->assertNotEmpty($payout->paymongo_reference);
        $this->assertNotEmpty($payout->idempotency_key);

        // Verify reward amount matches admin panel template
        $this->assertEquals((float) $template->reward_amount, (float) $payout->reward_amount);

        // 3. Reward Approved — mock PayMongo transfer
        $mockGateway = Mockery::mock(PaymentGatewayManager::class);
        $mockGateway->shouldReceive('createPayout')->once()->andReturn([
            'id' => 'tr_test_123',
            'status' => 'pending',
            'provider' => 'paymongo',
        ]);
        $mockGateway->shouldReceive('resolveProvider')->andReturn('paymongo');
        $this->app->instance(PaymentGatewayManager::class, $mockGateway);

        $processing = MissionRewardPayoutService::processPayout($payout);
        $this->assertEquals(MissionRewardPayout::STATUS_PROCESSING, $processing->status);
        $this->assertEquals('tr_test_123', $processing->paymongo_transfer_id);
        $this->assertEquals('paymongo', $processing->provider);

        // 4. PayMongo Processing — transaction recorded with PayMongo reference
        $this->assertDatabaseHas('mission_reward_payouts', [
            'id' => $payout->id,
            'paymongo_transfer_id' => 'tr_test_123',
            'status' => 'processing',
        ]);

        // 5. Webhook Confirmation — simulate transfer.succeeded webhook
        // Wallet should NOT be credited yet before webhook
        $walletBefore = $user->wallet->fresh()->balance;
        $this->assertEquals(0, (float) $walletBefore);

        $confirmed = MissionRewardPayoutService::confirmPayoutSuccess('tr_test_123', [
            'id' => 'tr_test_123',
            'external_id' => $payout->paymongo_reference,
            'status' => 'SUCCEEDED',
            'event_type' => 'transfer.succeeded',
        ]);

        $this->assertEquals(MissionRewardPayout::STATUS_SUCCESSFUL, $confirmed->status);
        $this->assertNotNull($confirmed->processed_at);

        // 6. Rider Reward Updated — wallet credited
        $walletAfter = $user->wallet->fresh()->balance;
        $this->assertEquals(200.00, (float) $walletAfter);

        // Wallet transaction recorded
        $this->assertDatabaseHas('wallet_transactions', [
            'wallet_id' => $user->wallet->id,
            'type' => 'credit',
            'source_type' => 'mission_reward_payout',
            'source_id' => $payout->id,
        ]);

        // 7. Transaction Recorded — detailed row with all required fields
        $final = MissionRewardPayout::find($payout->id);
        $this->assertEquals($user->id, $final->rider_user_id);
        $this->assertEquals($mission->id, $final->mission_id);
        $this->assertEquals(200.00, (float) $final->reward_amount);
        $this->assertEquals('tr_test_123', $final->paymongo_transfer_id);
        $this->assertNotNull($final->requested_at);
        $this->assertNotNull($final->processed_at);
        $this->assertEquals('successful', $final->status);

        // 8. Admin Panel Updated — admin can see successful reimbursement
        $admin = User::factory()->create(['role' => 'admin']);
        $response = $this->actingAs($admin, 'sanctum')->getJson('/api/v1/admin/mission-rewards');
        $response->assertOk()->assertJsonFragment(['paymongo_transfer_id' => 'tr_test_123']);

        // 9. Prevent Duplicate Rewards — second claim must not duplicate
        $duplicate = MissionRewardPayoutService::validateAndCreatePayout($mission, $user);
        $this->assertEquals($payout->id, $duplicate->id); // same row returned, no duplicate
        $this->assertEquals(1, MissionRewardPayout::where('mission_id', $mission->id)->count());

        // Even if processPayout retried while processing/successful, no duplicate PayMongo call
        $again = MissionRewardPayoutService::processPayout($duplicate);
        $this->assertEquals('successful', $again->fresh()->status);
        // Mock expectation was once, so no second call happened (would fail if called again)
    }

    public function test_duplicate_protection_under_retry(): void
    {
        $data = $this->createDriverWithMission(100.00);
        $user = $data['user'];
        $mission = $data['mission'];

        $payout1 = MissionRewardPayoutService::validateAndCreatePayout($mission, $user);
        $payout2 = MissionRewardPayoutService::validateAndCreatePayout($mission, $user);
        $this->assertEquals($payout1->id, $payout2->id);
        $this->assertEquals(1, MissionRewardPayout::count());
    }

    public function test_reward_amount_must_match_template(): void
    {
        $data = $this->createDriverWithMission(500.00);
        $user = $data['user'];
        $mission = $data['mission'];
        $template = $data['template'];

        // Change template reward after mission completed — payout should still use current template amount (validated)
        $template->update(['reward_amount' => 600.00]);
        $mission->refresh();
        $payout = MissionRewardPayoutService::validateAndCreatePayout($mission, $user);
        $this->assertEquals(600.00, (float) $payout->reward_amount);
    }

    public function test_failure_handling_and_retry(): void
    {
        $data = $this->createDriverWithMission(150.00);
        $user = $data['user'];
        $mission = $data['mission'];

        $payout = MissionRewardPayoutService::validateAndCreatePayout($mission, $user);

        $mockGateway = Mockery::mock(PaymentGatewayManager::class);
        $mockGateway->shouldReceive('createPayout')->once()->andThrow(new \RuntimeException('PayMongo insufficient balance'));
        $this->app->instance(PaymentGatewayManager::class, $mockGateway);

        try {
            MissionRewardPayoutService::processPayout($payout);
            $this->fail('Should have thrown');
        } catch (\RuntimeException $e) {
            $this->assertStringContainsString('PayMongo', $e->getMessage());
        }

        $fresh = $payout->fresh();
        $this->assertEquals('failed', $fresh->status);
        $this->assertNotNull($fresh->failure_reason);
        // Wallet must NOT be credited on failure
        $this->assertEquals(0, (float) $user->wallet->fresh()->balance);
        $this->assertFalse($mission->fresh()->reward_claimed);

        // Retry should work after fixing gateway
        $mockGateway2 = Mockery::mock(PaymentGatewayManager::class);
        $mockGateway2->shouldReceive('createPayout')->once()->andReturn(['id' => 'tr_retry_123', 'status' => 'pending', 'provider' => 'paymongo']);
        $this->app->instance(PaymentGatewayManager::class, $mockGateway2);

        $retried = MissionRewardPayoutService::retryPayout($fresh);
        $this->assertEquals('processing', $retried->status);
        $this->assertEquals('tr_retry_123', $retried->paymongo_transfer_id);
        $this->assertEquals($payout->id, $retried->id); // same row, no duplicate

        // Webhook confirms retry
        MissionRewardPayoutService::confirmPayoutSuccess('tr_retry_123', ['event_type' => 'transfer.succeeded']);
        $this->assertEquals(150.00, (float) $user->wallet->fresh()->balance);
    }

    public function test_webhook_idempotency(): void
    {
        $data = $this->createDriverWithMission(100.00);
        $user = $data['user'];
        $mission = $data['mission'];

        $payout = MissionRewardPayoutService::validateAndCreatePayout($mission, $user);
        $mockGateway = Mockery::mock(PaymentGatewayManager::class);
        $mockGateway->shouldReceive('createPayout')->andReturn(['id' => 'tr_webhook_dup', 'status' => 'pending', 'provider' => 'paymongo']);
        $this->app->instance(PaymentGatewayManager::class, $mockGateway);
        MissionRewardPayoutService::processPayout($payout);

        // First webhook
        MissionRewardPayoutService::confirmPayoutSuccess('tr_webhook_dup', ['event_type' => 'transfer.succeeded']);
        $balance1 = (float) $user->wallet->fresh()->balance;
        $this->assertEquals(100.00, $balance1);

        // Duplicate webhook — should not double credit
        MissionRewardPayoutService::confirmPayoutSuccess('tr_webhook_dup', ['event_type' => 'transfer.succeeded']);
        $balance2 = (float) $user->wallet->fresh()->balance;
        $this->assertEquals(100.00, $balance2);
        $this->assertEquals(1, \App\Models\WalletTransaction::where('source_type', 'mission_reward_payout')->where('source_id', $payout->id)->count());
    }
}
