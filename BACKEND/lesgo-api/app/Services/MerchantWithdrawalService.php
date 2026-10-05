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

            $partner = $locked->partner;

            if ($partner && $partner->user) {
                WalletService::credit(
                    $partner->user,
                    (float) $locked->amount,
                    'Withdrawal cancelled ' . $locked->reference_number,
                    MerchantWithdrawalRequest::class,
                    $locked->id,
                );
            }

            $locked->update([
                'status' => MerchantWithdrawalRequest::STATUS_CANCELLED,
            ]);

            return $locked->load(['user', 'wallet', 'partner']);
        });
    }
}
