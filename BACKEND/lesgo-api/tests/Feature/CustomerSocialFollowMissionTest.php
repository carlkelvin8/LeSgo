<?php

namespace Tests\Feature;

use App\Models\CustomerMission;
use App\Models\SocialShare;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class CustomerSocialFollowMissionTest extends TestCase
{
    private function mission(User $user, array $attributes = []): CustomerMission
    {
        $mission = CustomerMission::create(array_merge([
            'user_id' => $user->id,
            'mission_type' => 'social_follow',
            'title' => 'Follow FB page',
            'goal_target' => 1,
            'reward_type' => 'voucher',
            'reward_value' => 25,
            'mission_date' => now()->toDateString(),
        ], $attributes));

        // SQLite retains the cast's time component in DATE columns; normalize
        // the fixture to the date-only storage used by MySQL in production.
        DB::table('customer_missions')->where('id', $mission->id)->update([
            'mission_date' => now()->toDateString(),
        ]);

        return $mission;
    }

    public function test_client_confirmation_cannot_create_follow_proof(): void
    {
        $user = $this->actingAsRole('customer');

        $this->postJson('/api/v1/social/follow/confirm', [
            'platform' => 'facebook',
            'verified' => true,
        ])->assertStatus(422);

        $this->assertDatabaseMissing('social_shares', ['user_id' => $user->id]);
    }

    public function test_forged_follow_completion_never_changes_progress_or_credits_rewards(): void
    {
        $user = $this->actingAsRole('customer');
        $mission = $this->mission($user);
        $wallet = Wallet::factory()->create(['user_id' => $user->id, 'balance' => 100]);
        $payload = [
            'platform' => 'facebook',
            'verified' => true,
            'is_completed' => true,
            'current_progress' => 1,
        ];

        $this->postJson('/api/v1/social/follow/confirm', $payload)->assertStatus(422);
        $this->postJson("/api/v1/missions/{$mission->id}/progress", $payload)->assertStatus(422);
        $this->postJson("/api/v1/missions/{$mission->id}/claim", $payload)->assertStatus(400);

        $mission->refresh();
        $this->assertFalse($mission->is_completed);
        $this->assertFalse($mission->reward_claimed);
        $this->assertSame(0, $mission->current_progress);
        $this->assertNull($mission->completed_at);
        $this->assertNull($mission->claimed_at);
        $this->assertEquals(100, $wallet->fresh()->balance);
        $this->assertDatabaseMissing('social_shares', ['user_id' => $user->id]);
        $this->assertDatabaseCount('wallet_transactions', 0);
    }

    public function test_facebook_shares_and_legacy_follow_records_cannot_complete_a_mission(): void
    {
        $user = $this->actingAsRole('customer');
        $mission = $this->mission($user, [
            'current_progress' => 1,
            'is_completed' => true,
            'completed_at' => now(),
        ]);
        foreach (['referral', 'social_follow'] as $type) {
            SocialShare::create([
                'user_id' => $user->id,
                'platform' => 'facebook',
                'share_type' => $type,
                'share_title' => 'Legacy share',
                'share_description' => 'Unverified customer action',
                'share_url' => 'https://example.test/share',
            ]);
        }

        $this->postJson("/api/v1/missions/{$mission->id}/progress")->assertStatus(422);
        $response = $this->getJson('/api/v1/missions');
        $this->assertSame(200, $response->status(), $response->getContent());

        $mission->refresh();
        $this->assertFalse($mission->is_completed);
        $this->assertSame(0, $mission->current_progress);
        $this->assertNull($mission->completed_at);
    }

    public function test_legacy_completed_mission_cannot_pay_out_before_refresh(): void
    {
        $user = $this->actingAsRole('customer');
        $wallet = Wallet::factory()->create(['user_id' => $user->id, 'balance' => 100]);
        $mission = $this->mission($user, ['current_progress' => 1, 'is_completed' => true]);

        $this->postJson("/api/v1/missions/{$mission->id}/claim")->assertStatus(400);

        $this->assertFalse($mission->fresh()->reward_claimed);
        $this->assertEquals(100, $wallet->fresh()->balance);
        $this->assertDatabaseCount('wallet_transactions', 0);
    }

    public function test_refresh_preserves_previously_paid_history(): void
    {
        $user = $this->actingAsRole('customer');
        $mission = $this->mission($user, [
            'current_progress' => 1,
            'is_completed' => true,
            'completed_at' => now(),
            'reward_claimed' => true,
            'claimed_at' => now(),
        ]);

        $response = $this->getJson('/api/v1/missions');
        $this->assertSame(200, $response->status(), $response->getContent());

        $mission->refresh();
        $this->assertTrue($mission->is_completed);
        $this->assertTrue($mission->reward_claimed);
        $this->assertSame(1, $mission->current_progress);
    }

    public function test_other_completed_missions_can_still_claim_once(): void
    {
        $user = $this->actingAsRole('customer');
        $wallet = Wallet::factory()->create(['user_id' => $user->id, 'balance' => 100]);
        $mission = $this->mission($user, [
            'mission_type' => 'leseat_order',
            'current_progress' => 1,
            'is_completed' => true,
        ]);

        $this->postJson("/api/v1/missions/{$mission->id}/claim")->assertOk();
        $this->postJson("/api/v1/missions/{$mission->id}/claim")->assertStatus(400);

        $this->assertEquals(125, $wallet->fresh()->balance);
    }
}
