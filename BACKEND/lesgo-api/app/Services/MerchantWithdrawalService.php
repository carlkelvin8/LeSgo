<?php

namespace App\Services;

use App\Models\MerchantWithdrawalRequest;
use App\Models\Partner;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Support\Facades\DB;

class MerchantWithdrawalService
{
    /**
     * Create a withdrawal request and reserve (debit) the funds atomically.
     *
     * The wallet row is locked for update so concurrent requests cannot both
     * pass the balance check. Funds are debited immediately and released again
     * if the request is later cancelled.
     *
     * @param  array{amount: float|string, payout_method: string, payout_account_number: string, payout_account_name: string, payout_bank_name?: string|null}  $data
     *
     * @throws \RuntimeException when the wallet is missing or the balance is insufficient
     */
    public static function request(User $actor, Partner $partner, array $data): MerchantWithdrawalRequest
    {
        $amount = round((float) $data['amount'], 2);
        $fee = 0.00;
        $netAmount = round($amount - $fee, 2);

        $withdrawal = DB::transaction(function () use ($actor, $partner, $data, $amount, $fee, $netAmount) {
            $wallet = Wallet::query()
                ->where('user_id', $partner->user_id)
                ->lockForUpdate()
                ->first();

            if (! $wallet) {
                throw new \RuntimeException('Wallet not found for this merchant.');
            }

            $balance = (float) $wallet->balance;

            if ($balance < $amount) {
                throw new \RuntimeException(sprintf(
                    'Insufficient available balance. You have PHP %s available.',
                    number_format($balance, 2)
                ));
            }

            $withdrawal = MerchantWithdrawalRequest::create([
                'user_id' => $actor->id,
                'wallet_id' => $wallet->id,
                'partner_id' => $partner->id,
                'amount' => $amount,
                'fee' => $fee,
                'net_amount' => $netAmount,
                'currency' => $wallet->currency ?? 'PHP',
                'status' => MerchantWithdrawalRequest::STATUS_PENDING,
                'payout_method' => $data['payout_method'],
                'payout_account_number' => $data['payout_account_number'],
                'payout_account_name' => $data['payout_account_name'],
                'payout_bank_name' => $data['payout_bank_name'] ?? null,
                'reference_number' => MerchantWithdrawalRequest::generateReferenceNumber(),
            ]);

            // Reserve the funds immediately so they cannot be spent twice.
            WalletService::debit(
                $wallet->user,
                $amount,
                'Withdrawal request ' . $withdrawal->reference_number,
                MerchantWithdrawalRequest::class,
                $withdrawal->id,
            );

            return $withdrawal;
        });

        return $withdrawal->load(['user', 'wallet', 'partner']);
    }

    /**
     * Cancel a pending withdrawal and release the reserved funds back to the wallet.
     *
     * @throws \RuntimeException when the request can no longer be cancelled
     */
    public static function cancel(MerchantWithdrawalRequest $withdrawal): MerchantWithdrawalRequest
    {
        return DB::transaction(function () use ($withdrawal) {
            $locked = MerchantWithdrawalRequest::query()
                ->whereKey($withdrawal->id)
                ->lockForUpdate()
                ->firstOrFail();

            if (! $locked->canBeCancelled()) {
                throw new \RuntimeException("Cannot cancel withdrawal in '{$locked->status}' status.");
            }

            // Never mark it cancelled without giving the money back.
            self::releaseReservedFunds($locked, 'Withdrawal cancelled ' . $locked->reference_number);

            $locked->update([
                'status' => MerchantWithdrawalRequest::STATUS_CANCELLED,
            ]);

            return $locked->load(['user', 'wallet', 'partner']);
        });
    }

    /** Admin: accept a pending request and start paying it out. */
    public static function approve(MerchantWithdrawalRequest $withdrawal, User $admin, ?string $notes = null): MerchantWithdrawalRequest
    {
        return self::transition($withdrawal, [MerchantWithdrawalRequest::STATUS_PENDING], function ($locked) use ($admin, $notes) {
            $locked->update([
                'status' => MerchantWithdrawalRequest::STATUS_PROCESSING,
                'approved_by' => $admin->id,
                'approved_at' => now(),
                'admin_notes' => $notes ?? $locked->admin_notes,
            ]);
        });
    }

    /** Admin: the payout was sent. Funds stay debited. */
    public static function complete(MerchantWithdrawalRequest $withdrawal, User $admin, ?string $notes = null): MerchantWithdrawalRequest
    {
        return self::transition($withdrawal, [
            MerchantWithdrawalRequest::STATUS_PENDING,
            MerchantWithdrawalRequest::STATUS_PROCESSING,
        ], function ($locked) use ($admin, $notes) {
            $locked->update([
                'status' => MerchantWithdrawalRequest::STATUS_COMPLETED,
                'approved_by' => $locked->approved_by ?? $admin->id,
                'approved_at' => $locked->approved_at ?? now(),
                'processed_by' => $admin->id,
                'processed_at' => now(),
                'completed_at' => now(),
                'admin_notes' => $notes ?? $locked->admin_notes,
            ]);
        });
    }

    /** Admin: refuse the request. The reserved funds go back to the wallet. */
    public static function reject(MerchantWithdrawalRequest $withdrawal, User $admin, string $reason): MerchantWithdrawalRequest
    {
        return self::transition($withdrawal, [
            MerchantWithdrawalRequest::STATUS_PENDING,
            MerchantWithdrawalRequest::STATUS_PROCESSING,
        ], function ($locked) use ($admin, $reason) {
            self::releaseReservedFunds($locked, 'Withdrawal rejected ' . $locked->reference_number);
            $locked->update([
                'status' => MerchantWithdrawalRequest::STATUS_REJECTED,
                'rejection_reason' => $reason,
                'processed_by' => $admin->id,
                'processed_at' => now(),
            ]);
        });
    }

    /** Admin: the payout was attempted and failed. Funds go back to the wallet. */
    public static function fail(MerchantWithdrawalRequest $withdrawal, User $admin, ?string $reason = null): MerchantWithdrawalRequest
    {
        return self::transition($withdrawal, [MerchantWithdrawalRequest::STATUS_PROCESSING], function ($locked) use ($admin, $reason) {
            self::releaseReservedFunds($locked, 'Withdrawal failed ' . $locked->reference_number);
            $locked->update([
                'status' => MerchantWithdrawalRequest::STATUS_FAILED,
                'rejection_reason' => $reason,
                'processed_by' => $admin->id,
                'processed_at' => now(),
            ]);
        });
    }

    /**
     * Lock the request, check it is in an allowed state, run the change, return it.
     *
     * @param  array<int, string>  $allowedFrom
     */
    private static function transition(MerchantWithdrawalRequest $withdrawal, array $allowedFrom, \Closure $apply): MerchantWithdrawalRequest
    {
        return DB::transaction(function () use ($withdrawal, $allowedFrom, $apply) {
            $locked = MerchantWithdrawalRequest::query()
                ->whereKey($withdrawal->id)
                ->lockForUpdate()
                ->firstOrFail();

            if (! in_array($locked->status, $allowedFrom, true)) {
                throw new \RuntimeException("Cannot change a withdrawal that is '{$locked->status}'.");
            }

            $apply($locked);

            return $locked->fresh(['user', 'wallet', 'partner']);
        });
    }

    /** Credit the reserved amount back once; refuses to silently skip. */
    private static function releaseReservedFunds(MerchantWithdrawalRequest $locked, string $description): void
    {
        $owner = $locked->partner?->user;
        if (! $owner) {
            throw new \RuntimeException('Cannot release the funds: the merchant account was not found.');
        }

        WalletService::credit(
            $owner,
            (float) $locked->amount,
            $description,
            MerchantWithdrawalRequest::class,
            $locked->id,
        );
    }
}
