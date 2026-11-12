<?php

namespace Tests\Feature;

use App\Models\Partner;
use App\Models\PartnerStaff;
use App\Models\User;
use App\Models\Wallet;
use App\Services\RegistrationFeeService;
use Tests\TestCase;

class MerchantWithdrawalTest extends TestCase
{
    private function merchant(float $balance = 1000): Partner
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'active']);

        $fee = RegistrationFeeService::ensurePaymentRecord($owner);
        $fee->update([
            'payment_status' => 'waived',
            'waived_at' => now(),
            'application_status' => 'approved',
            'is_active' => true,
        ]);

        $wallet = Wallet::firstOrCreate(['user_id' => $owner->id], ['currency' => 'PHP']);
        $wallet->update(['balance' => $balance]);

        return $partner;
    }

    /** @param array<int, string> $permissions */
    private function staff(Partner $partner, string $role, array $permissions = []): User
    {
        $user = User::factory()->create(['role' => 'partner_staff']);

        PartnerStaff::create([
            'partner_id' => $partner->id,
            'user_id' => $user->id,
            'role' => $role,
            'permissions' => $permissions ?: null,
            'is_active' => true,
        ]);

        return $user;
    }

    /** @param array<string, mixed> $overrides */
    private function payload(array $overrides = []): array
    {
        return array_merge([
            'amount' => 250,
            'payout_method' => 'gcash',
            'payout_account_number' => '09171234567',
            'payout_account_name' => 'Test Merchant',
        ], $overrides);
    }

    public function test_owner_withdrawal_debits_wallet_and_creates_pending_request(): void
    {
        $partner = $this->merchant();
        $wallet = Wallet::where('user_id', $partner->user_id)->first();

        $this->actingAs($partner->user, 'sanctum')
            ->postJson('/api/v1/merchant/withdrawals', $this->payload())
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending');

        $this->assertSame(750.0, (float) $wallet->fresh()->balance);
        $this->assertDatabaseHas('merchant_withdrawal_requests', [
            'partner_id' => $partner->id,
            'status' => 'pending',
        ]);
        $this->assertDatabaseHas('wallet_transactions', [
            'wallet_id' => $wallet->id,
            'type' => 'debit',
        ]);
    }

    public function test_withdrawal_beyond_balance_is_rejected_without_debit(): void
    {
        $partner = $this->merchant(100);
        $wallet = Wallet::where('user_id', $partner->user_id)->first();

        $this->actingAs($partner->user, 'sanctum')
            ->postJson('/api/v1/merchant/withdrawals', $this->payload(['amount' => 500]))
            ->assertStatus(422)
            ->assertJsonPath('success', false);

        $this->assertSame(100.0, (float) $wallet->fresh()->balance);
        $this->assertDatabaseCount('merchant_withdrawal_requests', 0);
    }

    public function test_cancelling_pending_withdrawal_credits_funds_back(): void
    {
        $partner = $this->merchant();
        $wallet = Wallet::where('user_id', $partner->user_id)->first();

        $id = $this->actingAs($partner->user, 'sanctum')
            ->postJson('/api/v1/merchant/withdrawals', $this->payload())
            ->assertCreated()
            ->json('data.id');

        $this->assertSame(750.0, (float) $wallet->fresh()->balance);

        $this->postJson("/api/v1/merchant/withdrawals/{$id}/cancel")
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled');

        $this->assertSame(1000.0, (float) $wallet->fresh()->balance);
        $this->assertDatabaseHas('wallet_transactions', [
            'wallet_id' => $wallet->id,
            'type' => 'credit',
        ]);
    }

    public function test_cook_staff_cannot_request_withdrawal(): void
    {
        $partner = $this->merchant();
        $cook = $this->staff($partner, 'cook');

        $this->actingAs($cook, 'sanctum')
            ->postJson('/api/v1/merchant/withdrawals', $this->payload())
            ->assertForbidden();
    }

    public function test_cashier_staff_can_request_withdrawal(): void
    {
        $partner = $this->merchant();
        $cashier = $this->staff($partner, 'cashier');

        $this->actingAs($cashier, 'sanctum')
            ->postJson('/api/v1/merchant/withdrawals', $this->payload())
            ->assertCreated();
    }

    public function test_bank_transfer_requires_bank_name(): void
    {
        $partner = $this->merchant();

        $this->actingAs($partner->user, 'sanctum')
            ->postJson('/api/v1/merchant/withdrawals', $this->payload([
                'payout_method' => 'bank_transfer',
            ]))
            ->assertStatus(422);

        $this->actingAs($partner->user, 'sanctum')
            ->postJson('/api/v1/merchant/withdrawals', $this->payload([
                'payout_method' => 'bank_transfer',
                'payout_bank_name' => 'BDO',
            ]))
            ->assertCreated();
    }

    public function test_summary_for_a_store_without_a_wallet_starts_at_zero(): void
    {
        $partner = $this->merchant();
        Wallet::where('user_id', $partner->user_id)->delete();

        $this->actingAs($partner->user, 'sanctum')
            ->getJson('/api/v1/merchant/withdrawals/summary')
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('wallets', ['user_id' => $partner->user_id]);
    }

    public function test_customer_cannot_access_merchant_withdrawals(): void
    {
        $this->actingAs(User::factory()->create(['role' => 'customer']), 'sanctum')
            ->postJson('/api/v1/merchant/withdrawals', $this->payload())
            ->assertForbidden();
    }

    private function pendingRequest(Partner $partner): int
    {
        $this->actingAs($partner->user, 'sanctum')
            ->postJson('/api/v1/merchant/withdrawals', $this->payload())
            ->assertCreated();

        return (int) \App\Models\MerchantWithdrawalRequest::where('partner_id', $partner->id)->latest('id')->value('id');
    }

    public function test_admin_rejecting_a_request_returns_the_reserved_funds_once(): void
    {
        $partner = $this->merchant();
        $wallet = Wallet::where('user_id', $partner->user_id)->first();
        $id = $this->pendingRequest($partner);
        $this->assertSame(750.0, (float) $wallet->fresh()->balance);

        $admin = User::factory()->create(['role' => 'admin']);

        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/merchant-withdrawals/{$id}/reject", ['reason' => 'Account mismatch'])
            ->assertOk()
            ->assertJsonPath('data.status', 'rejected');
        $this->assertSame(1000.0, (float) $wallet->fresh()->balance);

        // A second reject must not pay the money back again.
        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/merchant-withdrawals/{$id}/reject", ['reason' => 'again'])
            ->assertUnprocessable();
        $this->assertSame(1000.0, (float) $wallet->fresh()->balance);
    }

    public function test_admin_approve_then_complete_keeps_the_funds_debited(): void
    {
        $partner = $this->merchant();
        $wallet = Wallet::where('user_id', $partner->user_id)->first();
        $id = $this->pendingRequest($partner);
        $admin = User::factory()->create(['role' => 'admin']);

        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/merchant-withdrawals/{$id}/approve")
            ->assertOk()->assertJsonPath('data.status', 'processing');
        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/merchant-withdrawals/{$id}/complete")
            ->assertOk()->assertJsonPath('data.status', 'completed');

        $this->assertSame(750.0, (float) $wallet->fresh()->balance);
    }

    public function test_a_failed_payout_returns_the_funds_and_only_admins_can_process(): void
    {
        $partner = $this->merchant();
        $wallet = Wallet::where('user_id', $partner->user_id)->first();
        $id = $this->pendingRequest($partner);
        $admin = User::factory()->create(['role' => 'admin']);

        // The merchant cannot approve their own withdrawal.
        $this->actingAs($partner->user, 'sanctum')
            ->postJson("/api/v1/admin/merchant-withdrawals/{$id}/approve")
            ->assertForbidden();

        $this->actingAs($admin, 'sanctum')->postJson("/api/v1/admin/merchant-withdrawals/{$id}/approve")->assertOk();
        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/merchant-withdrawals/{$id}/fail", ['reason' => 'Bank rejected'])
            ->assertOk()->assertJsonPath('data.status', 'failed');

        $this->assertSame(1000.0, (float) $wallet->fresh()->balance);
    }
}
