<?php

namespace App\Services;

use App\Jobs\DeleteMediaObjectsJob;
use App\Models\Order;
use App\Models\User;
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
