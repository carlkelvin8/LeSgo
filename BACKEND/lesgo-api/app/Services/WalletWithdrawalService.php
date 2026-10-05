<?php

namespace App\Services;

use App\Models\User;
use App\Models\WalletLinkedAccount;
use App\Models\WalletWithdrawal;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class WalletWithdrawalService
{
    public static function channelCodeForProvider(string $provider): string
    {
        return match (strtolower($provider)) {
            'gcash' => 'PH_GCASH',
            'maya', 'paymaya' => 'PH_MAYA',
            default => throw new \InvalidArgumentException(
                'Unsupported withdrawal method. Use gcash or maya.'
            ),
        };
    }

    public static function normalizeAccountNumber(string $number): string
    {
        $digits = preg_replace('/\D+/', '', $number) ?? '';

        if (str_starts_with($digits, '63') && strlen($digits) === 12) {
            return '0'.substr($digits, 2);
        }

        if (str_starts_with($digits, '9') && strlen($digits) === 10) {
            return '0'.$digits;
        }

        return $digits;
    }

    /** @return array{payout: array, wallet: \App\Models\Wallet} */
    public static function process(User $user, float $amount, string $provider): array
    {
        $provider = strtolower($provider) === 'paymaya' ? 'maya' : strtolower($provider);
        $linked = WalletLinkedAccount::where('user_id', $user->id)
            ->where('provider', $provider)
            ->first();

        if (! $linked) {
            throw new \RuntimeException(
                'Link your '.($provider === 'gcash' ? 'GCash' : 'Maya').' account before withdrawing.'
            );
        }

        $meta = is_array($linked->meta) ? $linked->meta : [];
        $accountDetails = is_array($linked->account_details_encrypted)
            ? $linked->account_details_encrypted
            : [];
        $accountNumber = self::normalizeAccountNumber(
            (string) ($accountDetails['account_number'] ?? $meta['account_number'] ?? '')
        );
        $holderName = trim((string) (
            $accountDetails['account_holder_name']
            ?? $meta['account_holder_name']
            ?? $user->name
        ));

        if ($accountNumber === '' || strlen($accountNumber) < 10) {
            throw new \RuntimeException(
                'Linked account is missing a valid mobile number. Please re-link your account.'
            );
        }

        if ($holderName === '') {
            throw new \RuntimeException('Account holder name is required for withdrawal.');
        }

        WalletValidationService::ensureWalletExists($user);
        if (WalletValidationService::getWalletBalance($user) < $amount) {
            throw new \RuntimeException('Insufficient wallet balance.');
        }

        $referenceId = 'lespay-withdraw-'.$user->id.'-'.Str::uuid();
        $channelCode = self::channelCodeForProvider($provider);
        $gateway = app(PaymentGatewayManager::class);
        $gatewayProvider = $gateway->resolvePayoutProvider();

        $withdrawal = DB::transaction(function () use (
            $user,
            $amount,
            $provider,
            $referenceId,
            $accountNumber,
            $gatewayProvider,
        ) {
            $wallet = WalletValidationService::ensureWalletExists($user);
            $withdrawal = WalletWithdrawal::create([
                'user_id' => $user->id,
                'wallet_id' => $wallet->id,
                'amount' => $amount,
                'currency' => 'PHP',
                'status' => 'processing',
                'provider' => $gatewayProvider,
                'withdrawal_method' => $provider,
                'external_reference' => $referenceId,
                'account_last4' => substr($accountNumber, -4),
                'debited_at' => now(),
            ]);

            WalletService::debit(
                $user,
                $amount,
                'Withdrawal to '.strtoupper($provider),
                WalletWithdrawal::class,
                $withdrawal->id,
            );

            return $withdrawal;
        });

        try {
            $payout = $gateway->createPayout(
                $amount,
                $referenceId,
                $channelCode,
                $holderName,
                $accountNumber,
                'LesGo wallet withdrawal',
                $gatewayProvider,
            );
        } catch (\Throwable $error) {
            $withdrawal->update([
                'status' => 'verification_required',
                'failure_reason' => $error->getMessage(),
            ]);
            Log::critical('Payout response is uncertain; wallet funds remain reserved', [
                'withdrawal_id' => $withdrawal->id,
                'reference_id' => $referenceId,
                'provider' => $gatewayProvider,
                'error' => $error->getMessage(),
            ]);

            throw new \RuntimeException(
                'Withdrawal status could not be confirmed. Your funds remain reserved while support verifies the payout.'
            );
        }

        $normalizedStatus = $gateway->normalizePayoutStatus($payout);
        $withdrawal->update([
            'gateway_reference' => $payout['id'],
            'status' => $normalizedStatus === 'pending' ? 'submitted' : $normalizedStatus,
            'completed_at' => $normalizedStatus === 'succeeded' ? now() : null,
            'meta' => ['gateway_status' => $payout['status'] ?? null],
        ]);

        if ($normalizedStatus === 'failed') {
            self::applyGatewayStatus($withdrawal, 'failed', $payout);
            throw new \RuntimeException('The payout was rejected and your wallet balance was restored.');
        }

        $linked->update([
            'is_verified' => true,
            'meta' => array_merge($meta, [
                'last_withdrawal_at' => now()->toISOString(),
                'last_payout_id' => $payout['id'] ?? null,
                'last_payout_status' => $payout['status'] ?? null,
            ]),
        ]);

        $payout['provider'] = $gatewayProvider;
        $payout['withdrawal_id'] = $withdrawal->id;

        return [
            'payout' => $payout,
            'wallet' => WalletValidationService::ensureWalletExists($user)->fresh(),
        ];
    }

    public static function applyGatewayStatus(
        WalletWithdrawal $withdrawal,
        string $status,
        array $payload = [],
    ): void {
        DB::transaction(function () use ($withdrawal, $status, $payload) {
            $locked = WalletWithdrawal::query()
                ->whereKey($withdrawal->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($status === 'succeeded') {
                if ($locked->status !== 'reversed') {
                    $locked->update([
                        'status' => 'succeeded',
                        'completed_at' => $locked->completed_at ?? now(),
                        'failure_reason' => null,
                        'meta' => array_merge($locked->meta ?? [], ['gateway_payload' => $payload]),
                    ]);
                }

                return;
            }

            if ($status !== 'failed' || $locked->reversed_at !== null) {
                return;
            }

            if ($locked->user) {
                WalletService::credit(
                    $locked->user,
                    (float) $locked->amount,
                    'Withdrawal reversal — payout failed',
                    WalletWithdrawal::class,
                    $locked->id,
                );
            }

            $locked->update([
                'status' => 'reversed',
                'failed_at' => now(),
                'reversed_at' => now(),
                'failure_reason' => (string) (
                    $payload['failure_reason']
                    ?? $payload['message']
                    ?? 'Gateway reported payout failure.'
                ),
                'meta' => array_merge($locked->meta ?? [], ['gateway_payload' => $payload]),
            ]);
        });
    }
}
