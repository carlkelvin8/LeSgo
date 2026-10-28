<?php

namespace App\Services;

use App\Jobs\DeleteMediaObjectsJob;
use App\Models\MenuCategory;
use App\Models\MenuItem;
use App\Models\MerchantWithdrawalRequest;
use App\Models\Order;
use App\Models\Partner;
use App\Models\PartnerBranch;
use App\Models\PartnerStaff;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletWithdrawal;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AccountDeletionService
{
    public function __construct(
        private AuthenticationService $authService,
        private AccountPersonalDataPurger $personalDataPurger,
    ) {}

    public function isPermanentlyDeleted(User $user): bool
    {
        if (Schema::hasColumn('users', 'deleted_at') && $user->deleted_at !== null) {
            return true;
        }

        return str_ends_with(strtolower((string) $user->email), '@deleted.local');
    }

    /** @throws ValidationException */
    public function permanentlyDeleteCustomer(User $user, ?string $reason = null): void
    {
        $this->ensureRole($user, 'customer');
        $this->permanentlyDelete($user, $reason, isDriver: false);
    }

    /** @throws ValidationException */
    public function permanentlyDeleteDriver(User $user, ?string $reason = null): void
    {
        $this->ensureRole($user, 'driver');
        $this->permanentlyDelete($user, $reason, isDriver: true);
    }

    /**
     * Permanently delete a store owner (`partner_admin`).
     *
     * Blocked while the store has active orders, pending/processing payouts or
     * an unsettled (positive or negative) wallet balance. Otherwise the store
     * is closed and delisted, branches closed, menu unpublished, staff
     * memberships removed (staff accounts survive) and the owner anonymized.
     *
     * @throws ValidationException
     */
    public function permanentlyDeleteMerchantOwner(User $user, ?string $reason = null): void
    {
        if (! $user->isPartnerAdmin()) {
            throw ValidationException::withMessages([
                'account' => ['Only store owner accounts can use store owner account deletion.'],
            ]);
        }

        $this->permanentlyDeleteMerchant($user, $reason, isOwner: true);
    }

    /**
     * Permanently delete a store staff member (`partner_staff`).
     *
     * Staff are not unconditionally deletable: payout requests they submitted
     * that are still in flight, and any unsettled wallet of their own, block
     * deletion. The store itself is not affected.
     *
     * @throws ValidationException
     */
    public function permanentlyDeleteMerchantStaff(User $user, ?string $reason = null): void
    {
        if (! $user->isPartnerStaff()) {
            throw ValidationException::withMessages([
                'account' => ['Only store staff accounts can use staff account deletion.'],
            ]);
        }

        $this->permanentlyDeleteMerchant($user, $reason, isOwner: false);
    }

    private function permanentlyDeleteMerchant(User $user, ?string $reason, bool $isOwner): void
    {
        $mediaPaths = DB::transaction(function () use ($user, $reason, $isOwner) {
            /** @var User $lockedUser */
            $lockedUser = User::query()
                ->lockForUpdate()
                ->findOrFail($user->getKey());

            if ($this->isPermanentlyDeleted($lockedUser)) {
                throw ValidationException::withMessages([
                    'account' => ['This account has already been deleted.'],
                ]);
            }

            $partner = $isOwner
                ? Partner::query()->where('user_id', $lockedUser->id)->lockForUpdate()->first()
                : null;

            $this->ensureMerchantHasNoActiveOrders($lockedUser, $partner);
            $this->ensureMerchantHasNoPendingPayouts($lockedUser, $partner);
            $this->ensureNoPendingWithdrawals($lockedUser);
            $this->ensureMerchantWalletIsSettled($lockedUser);

            // Collected inside the transaction, deleted only after commit.
            $paths = $this->personalDataPurger->collectMediaPaths(
                $lockedUser,
                includeVerificationDocuments: false
            );

            if ($partner) {
                $this->closeStore($partner, $lockedUser);
            } else {
                PartnerStaff::query()->where('user_id', $lockedUser->id)->delete();
            }

            $this->personalDataPurger->purgeMerchantUser($lockedUser);
            $this->anonymizeUserRecord($lockedUser, $reason);
            $this->authService->revokeAllTokens($lockedUser);

            return $paths;
        }, 3);

        if ($mediaPaths !== []) {
            // afterCommit(): a rolled-back deletion never schedules file removal.
            DeleteMediaObjectsJob::dispatch($mediaPaths)->afterCommit();
        }

        AuditLogger::logAuth(
            $isOwner ? 'merchant_owner_permanently_deleted' : 'merchant_staff_permanently_deleted',
            $user->id,
            true
        );
    }

    /**
     * Close and delist the store, close its branches, unpublish its menu and
     * detach staff. Orders, payments, payouts, store documents and proof images
     * are intentionally left untouched so customer receipts and financial
     * records stay accurate.
     */
    private function closeStore(Partner $partner, User $owner): void
    {
        $partnerUpdates = ['is_open' => false, 'is_featured' => false];
        $partnerUpdates['status'] = 'closed';

        // Registration copies the owner's personal contact details onto the
        // store. Clear them only when they are provably the owner's own.
        if ($partner->support_email !== null
            && strcasecmp((string) $partner->support_email, (string) $owner->email) === 0) {
            $partnerUpdates['support_email'] = null;
        }
        if ($partner->support_phone !== null
            && $owner->phone_number !== null
            && (string) $partner->support_phone === (string) $owner->phone_number) {
            $partnerUpdates['support_phone'] = null;
        }

        $partner->forceFill($partnerUpdates)->saveQuietly();

        if (Schema::hasTable('partner_branches') && Schema::hasColumn('partner_branches', 'is_open')) {
            PartnerBranch::query()->where('partner_id', $partner->id)->update(['is_open' => false]);
        }

        if (Schema::hasTable('menu_items') && Schema::hasColumn('menu_items', 'is_available')) {
            MenuItem::query()->where('partner_id', $partner->id)->update(['is_available' => false]);
        }
        if (Schema::hasTable('menu_categories') && Schema::hasColumn('menu_categories', 'is_active')) {
            MenuCategory::query()->where('partner_id', $partner->id)->update(['is_active' => false]);
        }

        // Staff keep their user accounts; their membership and sessions go.
        $staffUserIds = PartnerStaff::query()
            ->where('partner_id', $partner->id)
            ->pluck('user_id');

        PartnerStaff::query()->where('partner_id', $partner->id)->delete();

        User::query()->whereIn('id', $staffUserIds)->each(
            fn (User $staffUser) => $this->authService->revokeAllTokens($staffUser)
        );
    }

    private function ensureMerchantHasNoActiveOrders(User $user, ?Partner $partner): void
    {
        $hasActive = Order::query()->active()->forCustomer($user->id)->exists();

        if (! $hasActive && $partner !== null) {
            $hasActive = Order::query()->active()->where('partner_id', $partner->id)->exists();
        }

        if (! $hasActive) {
            return;
        }

        throw ValidationException::withMessages([
            'account' => [
                $partner !== null
                    ? 'Your store still has active orders. Complete or cancel them before deleting your account.'
                    : 'You have active orders. Please complete or cancel them before deleting your account.',
            ],
        ]);
    }

    private function ensureMerchantHasNoPendingPayouts(User $user, ?Partner $partner): void
    {
        if (! Schema::hasTable('merchant_withdrawal_requests')) {
            return;
        }

        $inFlight = [
            MerchantWithdrawalRequest::STATUS_PENDING,
            MerchantWithdrawalRequest::STATUS_PROCESSING,
        ];

        $query = MerchantWithdrawalRequest::query()
            ->whereIn('status', $inFlight)
            ->where(function ($q) use ($user, $partner) {
                $q->where('user_id', $user->id);
                if ($partner !== null) {
                    $q->orWhere('partner_id', $partner->id);
                }
            });

        if (! $query->lockForUpdate()->first(['id'])) {
            return;
        }

        throw ValidationException::withMessages([
            'account' => [
                $partner !== null
                    ? 'A store payout is still pending or processing. Wait for it to settle before deleting your account.'
                    : 'A payout request you submitted is still pending or processing. Wait for it to settle before deleting your account.',
            ],
        ]);
    }

    private function ensureMerchantWalletIsSettled(User $user): void
    {
        $wallet = Wallet::query()->where('user_id', $user->id)->lockForUpdate()->first();
        if (! $wallet) {
            return;
        }

        $balance = round((float) $wallet->balance, 2);
        if (abs($balance) < 0.01) {
            return;
        }

        throw ValidationException::withMessages([
            'account' => [
                $balance < 0
                    ? 'Your wallet has an outstanding negative balance. Settle it before deleting your account.'
                    : 'Please withdraw or settle your wallet balance before deleting your account.',
            ],
        ]);
    }

    private function permanentlyDelete(User $user, ?string $reason, bool $isDriver): void
    {
        $mediaPaths = DB::transaction(function () use ($user, $reason, $isDriver) {
            /** @var User $lockedUser */
            $lockedUser = User::query()
                ->with(['driverProfile', 'wallet'])
                ->lockForUpdate()
                ->findOrFail($user->getKey());

            if ($this->isPermanentlyDeleted($lockedUser)) {
                throw ValidationException::withMessages([
                    'account' => ['This account has already been deleted.'],
                ]);
            }

            $this->ensureNoActiveOrders($lockedUser, $isDriver);
            $this->ensureNoPendingWithdrawals($lockedUser);
            $this->ensureWalletIsSettled($lockedUser, $isDriver);

            $paths = $this->personalDataPurger->collectMediaPaths($lockedUser);

            if ($isDriver) {
                $this->personalDataPurger->purgeDriver($lockedUser);
            } else {
                $this->personalDataPurger->purgeCustomer($lockedUser);
            }

            $this->anonymizeUserRecord($lockedUser, $reason);
            $this->authService->revokeAllTokens($lockedUser);

            return $paths;
        }, 3);

        if ($mediaPaths !== []) {
            DeleteMediaObjectsJob::dispatch($mediaPaths)->afterCommit();
        }

        AuditLogger::logAuth('account_permanently_deleted', $user->id, true);
    }

    private function ensureRole(User $user, string $role): void
    {
        $hasRole = $role === 'driver' ? $user->isDriver() : $user->isCustomer();
        if ($hasRole) {
            return;
        }

        throw ValidationException::withMessages([
            'account' => [
                $role === 'driver'
                    ? 'Only driver accounts can use driver account deletion.'
                    : 'Only customer accounts can be permanently deleted from the app.',
            ],
        ]);
    }

    private function ensureNoActiveOrders(User $user, bool $isDriver): void
    {
        $query = Order::query()->active();

        if ($isDriver) {
            $driverProfileId = $user->driverProfile?->id;
            $hasActiveOrders = $driverProfileId !== null
                && $query->where('driver_id', $driverProfileId)->exists();
        } else {
            $hasActiveOrders = $query->forCustomer($user->id)->exists();
        }

        if (! $hasActiveOrders) {
            return;
        }

        throw ValidationException::withMessages([
            'account' => [
                $isDriver
                    ? 'You have active deliveries. Please complete or hand them off before deleting your account.'
                    : 'You have active orders. Please complete or cancel them before deleting your account.',
            ],
        ]);
    }

    private function ensureWalletIsSettled(User $user, bool $isDriver): void
    {
        $wallet = $user->wallet()->lockForUpdate()->first();
        if (! $wallet || abs((float) $wallet->balance) < 0.01) {
            return;
        }

        throw ValidationException::withMessages([
            'account' => [
                $isDriver
                    ? 'Please settle your LesPay wallet balance before deleting your account.'
                    : 'Please withdraw, use, or settle your LesPay wallet balance before deleting your account.',
            ],
        ]);
    }

    private function ensureNoPendingWithdrawals(User $user): void
    {
        if (! Schema::hasTable('wallet_withdrawals')) {
            return;
        }

        $pendingWithdrawal = WalletWithdrawal::query()
            ->where('user_id', $user->id)
            ->whereIn('status', WalletWithdrawal::ACTIVE_STATUSES)
            ->lockForUpdate()
            ->first(['id']);

        if (! $pendingWithdrawal) {
            return;
        }

        throw ValidationException::withMessages([
            'account' => [
                'A withdrawal is still being processed. Wait for it to settle before deleting your account.',
            ],
        ]);
    }

    private function anonymizeUserRecord(User $user, ?string $reason): void
    {
        $payload = [
            'name' => 'Deleted User',
            'email' => 'deleted_'.$user->id.'_'.Str::lower(Str::random(10)).'@deleted.local',
            'phone_number' => null,
            'google_id' => null,
            'address_line1' => null,
            'address_line2' => null,
            'profile_photo_url' => null,
            'profile_picture' => null,
            'date_of_birth' => null,
            'fcm_token' => null,
            'password' => Hash::make(Str::random(64)),
            'remember_token' => null,
            'referral_code' => null,
            'referred_by' => null,
            'points' => 0,
        ];

        if (Schema::hasColumn('users', 'apple_id')) {
            $payload['apple_id'] = null;
        }

        if (Schema::hasColumn('users', 'is_active')) {
            $payload['is_active'] = false;
        }

        if (Schema::hasColumn('users', 'deactivated_at')) {
            $payload['deactivated_at'] = now();
        }

        if (Schema::hasColumn('users', 'deactivation_reason')) {
            $payload['deactivation_reason'] = $reason ?: 'Permanent account deletion';
        }

        if (Schema::hasColumn('users', 'deleted_at')) {
            $payload['deleted_at'] = now();
        }

        $user->forceFill($payload)->save();
    }
}
