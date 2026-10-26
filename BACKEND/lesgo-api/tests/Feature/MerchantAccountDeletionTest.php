<?php

namespace Tests\Feature;

use App\Jobs\DeleteMediaObjectsJob;
use App\Models\DocumentVerification;
use App\Models\MenuCategory;
use App\Models\MenuItem;
use App\Models\MerchantWithdrawalRequest;
use App\Models\Order;
use App\Models\Partner;
use App\Models\PartnerBranch;
use App\Models\PartnerStaff;
use App\Models\Payment;
use App\Models\Service;
use App\Models\User;
use App\Models\Wallet;
use App\Services\AccountDeletionService;
use App\Services\AccountPersonalDataPurger;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class MerchantAccountDeletionTest extends TestCase
{
    private function store(array $partnerOverrides = [], array $ownerOverrides = []): array
    {
        $owner = User::factory()->create(array_merge([
            'role' => 'partner_admin',
            'email' => 'owner@example.com',
            'phone_number' => '+639171234567',
            'profile_photo_url' => 'profiles/owner.jpg',
        ], $ownerOverrides));

        $partner = Partner::factory()->create(array_merge([
            'user_id' => $owner->id,
            'name' => 'Mang Tomas Eatery',
            'status' => 'active',
            'is_open' => true,
            'is_featured' => true,
            'support_email' => 'owner@example.com',
            'support_phone' => '+639171234567',
            'documents' => ['business_permit' => 'store-docs/permit.jpg'],
        ], $partnerOverrides));

        return [$owner, $partner];
    }

    private function staffFor(Partner $partner): array
    {
        $user = User::factory()->create(['role' => 'partner_staff', 'email' => 'cook@example.com']);
        $membership = PartnerStaff::create([
            'partner_id' => $partner->id,
            'user_id' => $user->id,
            'role' => 'cook',
            'is_active' => true,
        ]);

        return [$user, $membership];
    }

    private function activeOrder(Partner $partner, string $status = 'pending'): Order
    {
        return Order::factory()->create([
            'partner_id' => $partner->id,
            'service_id' => Service::factory()->create()->id,
            'status' => $status,
        ]);
    }

    private function deleteAs(User $user, array $extra = [])
    {
        return $this->withToken($this->tokenFor($user))->postJson('/api/v1/auth/account/delete', array_merge([
            'password' => 'password',
            'confirmation' => 'DELETE',
        ], $extra));
    }

    private function payout(Partner $partner, User $requester, string $status, Wallet $wallet): MerchantWithdrawalRequest
    {
        return MerchantWithdrawalRequest::create([
            'user_id' => $requester->id,
            'wallet_id' => $wallet->id,
            'partner_id' => $partner->id,
            'amount' => 100,
            'fee' => 0,
            'net_amount' => 100,
            'status' => $status,
            'payout_method' => 'gcash',
            'payout_account_name' => 'Juan Dela Cruz',
            'payout_account_number' => '09171234567',
            'reference_number' => 'REF-'.uniqid(),
        ]);
    }

    public function test_owner_deletion_closes_store_and_preserves_records(): void
    {
        Queue::fake();
        [$owner, $partner] = $this->store();
        [$staffUser, $membership] = $this->staffFor($partner);
        $staffToken = $this->tokenFor($staffUser);

        $branch = PartnerBranch::create(['partner_id' => $partner->id, 'name' => 'Main', 'is_primary' => true, 'is_open' => true]);
        $category = MenuCategory::create(['partner_id' => $partner->id, 'name' => 'Meals', 'is_active' => true]);
        $item = MenuItem::create([
            'partner_id' => $partner->id, 'menu_category_id' => $category->id,
            'name' => 'Sinigang', 'price' => 120, 'is_available' => true, 'image_url' => 'menu/sinigang.jpg',
        ]);

        $completed = $this->activeOrder($partner, 'completed');
        $payment = Payment::create([
            'order_id' => $completed->id, 'amount' => 120, 'method' => 'cash', 'status' => 'paid',
            'provider_reference' => 'PAY-REF-1',
        ] + $this->paymentDefaults());
        $wallet = Wallet::factory()->create(['user_id' => $owner->id, 'balance' => 0]);
        $paidOut = $this->payout($partner, $owner, 'completed', $wallet);

        $verification = DocumentVerification::create([
            'user_id' => $owner->id, 'document_type' => 'business_permit',
            'document_urls' => ['docs/permit-scan.jpg'], 'status' => 'approved',
        ]);

        $this->deleteAs($owner)->assertOk();

        // Store: closed, delisted, branches closed, menu unpublished.
        $partner->refresh();
        $this->assertSame('closed', $partner->status);
        $this->assertFalse($partner->is_open);
        $this->assertFalse($partner->is_featured);
        $this->assertFalse($branch->fresh()->is_open);
        $this->assertFalse($item->fresh()->is_available);
        $this->assertFalse($category->fresh()->is_active);
        $this->assertNull($partner->support_email, "owner's personal contact copy is cleared");
        $this->assertNull($partner->support_phone);

        // Rows are kept, not hard-deleted.
        $this->assertNotNull($item->fresh());
        $this->assertSame('Mang Tomas Eatery', $partner->name, 'receipts keep the original store name');
        $this->assertSame(['business_permit' => 'store-docs/permit.jpg'], $partner->documents);

        // Staff keep their account but lose membership and sessions.
        $this->assertNotNull($staffUser->fresh());
        $this->assertNull(PartnerStaff::find($membership->id));
        $this->assertSame(0, $staffUser->tokens()->count());

        // Owner anonymized, tokens revoked.
        $owner->refresh();
        $this->assertStringEndsWith('@deleted.local', $owner->email);
        $this->assertNull($owner->phone_number);
        $this->assertSame(0, $owner->tokens()->count());

        // Financial + order history untouched.
        $this->assertSame('completed', $completed->fresh()->status);
        $this->assertSame($partner->id, $completed->fresh()->partner_id);
        $this->assertSame('PAY-REF-1', $payment->fresh()->provider_reference);
        $this->assertSame('09171234567', $paidOut->fresh()->payout_account_number);
        $this->assertSame('completed', $paidOut->fresh()->status);

        // Verification documents are retained pending a retention decision.
        $this->assertNotNull($verification->fresh());

        // File cleanup only covers the person's own media, never store/verification docs.
        Queue::assertPushed(DeleteMediaObjectsJob::class, function ($job) {
            $paths = (new \ReflectionClass($job))->getProperties();
            $flat = json_encode(array_map(fn ($p) => $p->getValue($job), $paths));

            return str_contains($flat, 'profiles\/owner.jpg')
                && ! str_contains($flat, 'permit')
                && ! str_contains($flat, 'sinigang');
        });

        // Old staff token no longer works.
        app('auth')->forgetGuards();
        $this->withToken($staffToken)->getJson('/api/v1/auth/me')->assertUnauthorized();
    }

    private function paymentDefaults(): array
    {
        // Fill any non-null columns without hard-coding the whole schema.
        $columns = \Illuminate\Support\Facades\Schema::getColumns('payments');
        $defaults = [];
        foreach ($columns as $c) {
            if (! $c['nullable'] && $c['default'] === null && ! $c['auto_increment']
                && ! in_array($c['name'], ['order_id', 'amount', 'method', 'status', 'provider_reference'], true)) {
                $defaults[$c['name']] = str_contains($c['type'], 'int') || str_contains($c['type'], 'decimal') ? 1 : 'x';
            }
        }

        return $defaults;
    }

    public function test_closed_store_is_delisted_and_shown_generically(): void
    {
        [$owner, $partner] = $this->store();
        $this->getJson('/api/v1/partners')->assertOk()->assertSee('Mang Tomas Eatery');

        $this->deleteAs($owner)->assertOk();

        $this->getJson('/api/v1/partners')->assertOk()->assertDontSee('Mang Tomas Eatery');
        $this->getJson('/api/v1/partners/'.$partner->id)
            ->assertOk()
            ->assertJsonPath('data.name', 'Closed store');
        $this->assertSame('Mang Tomas Eatery', Partner::find($partner->id)->name);
    }

    public function test_active_store_orders_block_owner_deletion(): void
    {
        Queue::fake();
        [$owner, $partner] = $this->store();
        $this->activeOrder($partner, 'pending');

        $this->deleteAs($owner)->assertUnprocessable();

        $this->assertSame('active', $partner->fresh()->status);
        $this->assertSame($owner->email, $owner->fresh()->email);
        Queue::assertNothingPushed();
    }

    public function test_pending_or_processing_payouts_block_owner_deletion(): void
    {
        [$owner, $partner] = $this->store();
        $wallet = Wallet::factory()->create(['user_id' => $owner->id, 'balance' => 0]);

        foreach (['pending', 'processing'] as $status) {
            $request = $this->payout($partner, $owner, $status, $wallet);
            $this->deleteAs($owner)->assertUnprocessable();
            $this->assertSame('active', $partner->fresh()->status);
            $request->delete();
        }

        // A payout submitted by staff for this store also blocks the owner.
        [$staffUser] = $this->staffFor($partner);
        $this->payout($partner, $staffUser, 'pending', $wallet);
        $this->deleteAs($owner)->assertUnprocessable();
    }

    public function test_positive_and_negative_wallet_balances_block_owner_deletion(): void
    {
        [$owner, $partner] = $this->store();
        $wallet = Wallet::factory()->create(['user_id' => $owner->id, 'balance' => 250.50]);

        $this->deleteAs($owner)->assertUnprocessable();

        $wallet->update(['balance' => -40]);
        $response = $this->deleteAs($owner)->assertUnprocessable();
        $this->assertStringContainsString('negative', json_encode($response->json()));

        $this->assertSame('active', $partner->fresh()->status);

        $wallet->update(['balance' => 0]);
        $this->deleteAs($owner)->assertOk();
        $this->assertSame('closed', $partner->fresh()->status);
    }

    public function test_completed_and_cancelled_orders_do_not_block(): void
    {
        [$owner, $partner] = $this->store();
        $this->activeOrder($partner, 'completed');
        $this->activeOrder($partner, 'cancelled');

        $this->deleteAs($owner)->assertOk();
    }

    public function test_failure_rolls_back_everything_and_schedules_no_file_cleanup(): void
    {
        Queue::fake();
        [$owner, $partner] = $this->store();
        [, $membership] = $this->staffFor($partner);
        $item = MenuItem::create([
            'partner_id' => $partner->id,
            'menu_category_id' => MenuCategory::create(['partner_id' => $partner->id, 'name' => 'Meals'])->id,
            'name' => 'Adobo', 'price' => 90, 'is_available' => true,
        ]);

        $this->app->bind(AccountPersonalDataPurger::class, function () {
            return new class extends AccountPersonalDataPurger {
                public function purgeMerchantUser(User $user): void
                {
                    throw new \RuntimeException('simulated failure after the store was closed');
                }
            };
        });

        try {
            app(AccountDeletionService::class)->permanentlyDeleteMerchantOwner($owner);
            $this->fail('Expected the simulated failure.');
        } catch (\RuntimeException $e) {
            $this->assertStringContainsString('simulated failure', $e->getMessage());
        }

        $this->assertSame('active', $partner->fresh()->status);
        $this->assertTrue($partner->fresh()->is_open);
        $this->assertTrue($item->fresh()->is_available);
        $this->assertNotNull(PartnerStaff::find($membership->id));
        $this->assertSame('owner@example.com', $owner->fresh()->email);
        Queue::assertNothingPushed();
    }

    public function test_staff_can_delete_their_account_without_affecting_the_store(): void
    {
        Queue::fake();
        [, $partner] = $this->store();
        [$staffUser, $membership] = $this->staffFor($partner);

        $this->deleteAs($staffUser)->assertOk();

        $this->assertNull(PartnerStaff::find($membership->id));
        $this->assertStringEndsWith('@deleted.local', $staffUser->fresh()->email);
        $this->assertSame('active', $partner->fresh()->status);
        $this->assertTrue($partner->fresh()->is_open);
    }

    public function test_staff_with_in_flight_payout_or_unsettled_wallet_cannot_delete(): void
    {
        [$owner, $partner] = $this->store();
        $ownerWallet = Wallet::factory()->create(['user_id' => $owner->id, 'balance' => 0]);
        [$staffUser, $membership] = $this->staffFor($partner);

        $payout = $this->payout($partner, $staffUser, 'processing', $ownerWallet);
        $this->deleteAs($staffUser)->assertUnprocessable();
        $this->assertNotNull(PartnerStaff::find($membership->id));

        $payout->update(['status' => 'completed']);
        $staffWallet = Wallet::factory()->create(['user_id' => $staffUser->id, 'balance' => -5]);
        $this->deleteAs($staffUser)->assertUnprocessable();

        $staffWallet->update(['balance' => 0]);
        $this->deleteAs($staffUser)->assertOk();
    }

    public function test_wrong_password_cannot_delete_a_merchant_account(): void
    {
        [$owner, $partner] = $this->store();

        $this->deleteAs($owner, ['password' => 'not-the-password'])->assertUnprocessable();
        $this->assertSame('active', $partner->fresh()->status);
    }

    public function test_already_deleted_owner_cannot_be_deleted_twice(): void
    {
        [$owner] = $this->store();
        $service = app(AccountDeletionService::class);
        $service->permanentlyDeleteMerchantOwner($owner);

        // The anonymized row is soft-deleted, so it can no longer be loaded at all.
        $this->expectException(\Illuminate\Database\Eloquent\ModelNotFoundException::class);
        $service->permanentlyDeleteMerchantOwner($owner);
    }
}
