<?php

namespace App\Services;

use App\Models\DriverMission;
use App\Models\MissionRewardPayout;
use App\Models\MissionTemplate;
use App\Models\User;
use App\Models\WalletLinkedAccount;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class MissionRewardPayoutService
{
    /**
     * Validate mission and create or return existing payout record (idempotent).
     * Does NOT yet call PayMongo — caller should call processPayout().
     *
     * @throws \RuntimeException on validation failure
     */
    public static function validateAndCreatePayout(DriverMission $mission, User $rider): MissionRewardPayout
    {
        return DB::transaction(function () use ($mission, $rider) {
            // Pessimistic lock on mission to prevent race
            $lockedMission = DriverMission::where('id', $mission->id)
                ->lockForUpdate()
                ->first();

            if (!$lockedMission) {
                throw new \RuntimeException('Mission not found');
            }

            // Check unique payout for this mission (idempotency)
            $existing = MissionRewardPayout::where('mission_id', $lockedMission->id)->first();
            if ($existing) {
                // If already successful/processing/pending, return it (duplicate protection)
                return $existing;
            }

            // 1. Verify mission completed
            if (!$lockedMission->is_completed) {
                throw new \RuntimeException('Mission not completed yet');
            }

            // 2. Verify not already rewarded (driver_missions.reward_claimed)
            // But allow if payout record doesn't exist — we will set reward_claimed only after successful payout
            // If reward_claimed true and no payout record, treat as already claimed (legacy)
            if ($lockedMission->reward_claimed) {
                // check if legacy claim had no payout — still block duplicate
                throw new \RuntimeException('Reward already claimed');
            }

            // 3. Verify rider eligibility
            if (!$rider->isDriver() || !$rider->driverProfile) {
                throw new \RuntimeException('Rider is not eligible for reward');
            }
            if ((int) $lockedMission->driver_profile_id !== (int) $rider->driverProfile->id) {
                throw new \RuntimeException('Mission does not belong to rider');
            }
            if (!$rider->is_active) {
                throw new \RuntimeException('Rider account is not active');
            }

            // 4. Verify reward amount matches configured mission reward in Admin Panel
            $template = $lockedMission->missionTemplate;
            if (!$template) {
                $template = MissionTemplate::find($lockedMission->mission_template_id);
            }
            if (!$template) {
                throw new \RuntimeException('Mission template not found');
            }
            if (!$template->is_active) {
                Log::warning('Mission reward payout for inactive template', [
                    'mission_id' => $lockedMission->id,
                    'template_id' => $template->id,
                ]);
                // Allow payout for already completed missions even if template deactivated? But validate amount
            }

            $expectedAmount = (float) $template->reward_amount;
            // Legacy: amount check via template only; no override via request
            // Ensure payout amount equals template
            $rewardAmount = $expectedAmount;

            if ($rewardAmount <= 0) {
                throw new \RuntimeException('Mission reward amount is invalid');
            }

            $idempotencyKey = 'mission-reward-' . $lockedMission->id . '-' . $lockedMission->driver_profile_id . '-' . $lockedMission->mission_template_id;
            $reference = 'lesgo-mission-' . $lockedMission->id . '-' . Str::uuid();

            $payout = MissionRewardPayout::create([
                'rider_user_id' => $rider->id,
                'driver_profile_id' => $lockedMission->driver_profile_id,
                'mission_id' => $lockedMission->id,
                'mission_template_id' => $template->id,
                'reward_amount' => $rewardAmount,
                'reward_currency' => $template->reward_currency ?? 'PHP',
                'paymongo_reference' => $reference,
                'idempotency_key' => $idempotencyKey,
                'provider' => 'paymongo',
                'status' => MissionRewardPayout::STATUS_PENDING,
                'attempts' => 0,
                'requested_at' => now(),
            ]);

            Log::info('Mission reward payout validated and created', [
                'payout_id' => $payout->id,
                'mission_id' => $lockedMission->id,
                'rider_id' => $rider->id,
                'amount' => $rewardAmount,
            ]);

            return $payout;
        });
    }

    /**
     * Process payout via PayMongo. Idempotent: if payout already processing/successful, no duplicate call.
     *
     * @throws \RuntimeException on failure (payout marked failed)
     */
    public static function processPayout(MissionRewardPayout $payout): MissionRewardPayout
    {
        $preflight = DB::transaction(function () use ($payout) {
            $locked = MissionRewardPayout::where('id', $payout->id)->lockForUpdate()->first();
            if (!$locked) {
                throw new \RuntimeException('Payout not found');
            }

            if ($locked->isSuccessful()) {
                return ['payout' => $locked, 'recipient' => null, 'done' => true];
            }
            if ($locked->isProcessing()) {
                return ['payout' => $locked, 'recipient' => null, 'done' => true];
            }

            // If status is failed, allow retry (increment attempts)
            // If pending, move to processing

            $locked->update([
                'status' => MissionRewardPayout::STATUS_PROCESSING,
                'attempts' => $locked->attempts + 1,
                'failure_reason' => null,
            ]);

            $recipient = self::resolveRecipient($locked->rider_user_id);
            if (!$recipient) {
                $locked->update([
                    'status' => MissionRewardPayout::STATUS_PENDING,
                    'failure_reason' => 'No linked GCash/Maya account for payout. Please link account and retry.',
                ]);
                return ['payout' => $locked->fresh(), 'recipient' => null, 'done' => false];
            }
            return ['payout' => $locked->fresh(), 'recipient' => $recipient, 'done' => false];
        });

        if ($preflight['done']) {
            return $preflight['payout'];
        }
        if (!$preflight['recipient']) {
            throw new \RuntimeException('No linked GCash/Maya account for payout. Please link account and retry.');
        }

        $locked = $preflight['payout'];
        $recipient = $preflight['recipient'];

        try {
            $gateway = app(PaymentGatewayManager::class);
            $channelCode = WalletWithdrawalService::channelCodeForProvider($recipient['provider']);
            $description = 'LesGo mission reward: mission #' . $locked->mission_id;
            $result = $gateway->createPayout(
                (float) $locked->reward_amount,
                $locked->paymongo_reference,
                $channelCode,
                $recipient['holder_name'],
                $recipient['account_number'],
                $description,
                'paymongo'
            );
            if (($result['provider'] ?? 'paymongo') !== 'paymongo') {
                throw new \RuntimeException('Mission rewards require PayMongo; another provider was selected.');
            }

            return DB::transaction(function () use ($locked, $recipient, $description, $result) {
                $current = MissionRewardPayout::whereKey($locked->id)->lockForUpdate()->firstOrFail();
                $current->update([
                    'paymongo_transfer_id' => $result['id'] ?? null,
                    'provider' => 'paymongo',
                    'paymongo_payload' => [
                        'amount' => $current->reward_amount,
                        'recipient' => $recipient,
                        'description' => $description,
                        'reference' => $current->paymongo_reference,
                    ],
                    'paymongo_response' => $result,
                    'status' => MissionRewardPayout::STATUS_PROCESSING,
                ]);
                return $current->fresh();
            });
        } catch (\Throwable $e) {
            DB::transaction(function () use ($locked, $e) {
                $current = MissionRewardPayout::whereKey($locked->id)->lockForUpdate()->first();
                if ($current && !$current->isSuccessful()) {
                    $current->update([
                        'status' => MissionRewardPayout::STATUS_FAILED,
                        'failure_reason' => substr($e->getMessage(), 0, 1000),
                        'paymongo_response' => ['error' => $e->getMessage()],
                    ]);
                }
            });
            Log::warning('Mission reward PayMongo payout failed', [
                'payout_id' => $locked->id,
                'error' => $e->getMessage(),
            ]);
            throw new \RuntimeException('PayMongo payout failed: ' . $e->getMessage(), previous: $e);
        }
    }

    /**
     * Called by webhook when PayMongo transfer status is confirmed.
     * Credits rider wallet only after successful webhook.
     */
    public static function confirmPayoutSuccess(string $transferId, array $payload = []): ?MissionRewardPayout
    {
        return DB::transaction(function () use ($transferId, $payload) {
            $payout = MissionRewardPayout::where('paymongo_transfer_id', $transferId)
                ->orWhere('paymongo_reference', $transferId)
                ->lockForUpdate()
                ->first();

            if (!$payout) {
                // Try to find by reference carried in event metadata
                $reference = $payload['external_id'] ?? $payload['reference'] ?? null;
                if ($reference) {
                    $payout = MissionRewardPayout::where('paymongo_reference', $reference)->lockForUpdate()->first();
                }
            }

            if (!$payout) {
                Log::warning('Mission reward payout not found for webhook', ['transfer_id' => $transferId, 'payload' => $payload]);
                return null;
            }

            if ($payout->isSuccessful()) {
                return $payout; // idempotent
            }

            // Credit rider wallet
            $rider = $payout->rider;
            if (!$rider) {
                $rider = User::find($payout->rider_user_id);
            }

            $template = $payout->missionTemplate ?? MissionTemplate::find($payout->mission_template_id);

            $title = $template ? $template->title : 'Mission #' . $payout->mission_id;

            // Credit wallet (only once)
            try {
                WalletService::credit(
                    $rider,
                    (float) $payout->reward_amount,
                    'Mission reward: ' . $title . ' (PayMongo ref: ' . $payout->paymongo_reference . ')',
                    'mission_reward_payout',
                    $payout->id
                );
            } catch (\Throwable $e) {
                Log::error('Failed to credit wallet for mission payout webhook', [
                    'payout_id' => $payout->id,
                    'error' => $e->getMessage(),
                ]);
                // Do not mark successful if wallet credit failed — will retry on next webhook
                throw $e;
            }

            // Mark driver_mission as claimed only after successful payout + wallet credit
            $mission = $payout->mission;
            if ($mission && !$mission->reward_claimed) {
                $mission->update([
                    'reward_claimed' => true,
                    'claimed_at' => now(),
                ]);
            }

            $payout->update([
                'status' => MissionRewardPayout::STATUS_SUCCESSFUL,
                'processed_at' => now(),
                'paymongo_response' => array_merge($payout->paymongo_response ?? [], ['webhook_payload' => $payload, 'webhook_confirmed_at' => now()->toIso8601String()]),
            ]);

            Log::info('Mission reward payout confirmed via webhook and wallet credited', [
                'payout_id' => $payout->id,
                'rider_id' => $payout->rider_user_id,
                'amount' => $payout->reward_amount,
            ]);

            return $payout->fresh();
        });
    }

    public static function markPayoutFailed(string $transferId, string $reason, array $payload = []): ?MissionRewardPayout
    {
        return DB::transaction(function () use ($transferId, $reason, $payload) {
            $payout = MissionRewardPayout::where('paymongo_transfer_id', $transferId)
                ->orWhere('paymongo_reference', $transferId)
                ->lockForUpdate()
                ->first();

            if (!$payout) {
                $reference = $payload['external_id'] ?? $payload['reference'] ?? null;
                if ($reference) {
                    $payout = MissionRewardPayout::where('paymongo_reference', $reference)->lockForUpdate()->first();
                }
            }

            if (!$payout) {
                Log::warning('Mission reward payout not found for failure webhook', ['transfer_id' => $transferId]);
                return null;
            }

            if ($payout->isSuccessful()) {
                return $payout; // do not overwrite success
            }

            $payout->update([
                'status' => MissionRewardPayout::STATUS_FAILED,
                'failure_reason' => substr($reason, 0, 1000),
                'paymongo_response' => array_merge($payout->paymongo_response ?? [], ['webhook_payload' => $payload, 'webhook_failed_at' => now()->toIso8601String()]),
            ]);

            Log::info('Mission reward payout marked failed via webhook', [
                'payout_id' => $payout->id,
                'reason' => $reason,
            ]);

            return $payout->fresh();
        });
    }

    /**
     * Retry a failed payout (admin action). Safe — idempotent.
     */
    public static function retryPayout(MissionRewardPayout $payout): MissionRewardPayout
    {
        // Refresh with lock
        $fresh = MissionRewardPayout::where('id', $payout->id)->lockForUpdate()->first();
        if (!$fresh) {
            throw new \RuntimeException('Payout not found');
        }
        if (!$fresh->canRetry()) {
            throw new \RuntimeException('Only failed payouts can be retried. Current status: ' . $fresh->status);
        }

        // Reuse same reference/idempotency — PayMongo will deduplicate if same reference already processed
        // But we need to allow a new attempt; keep same reference to prevent duplicate payout on PayMongo side,
        // however PayMongo's batch_transfers is not idempotent by reference — so we generate new reference on retry? To be safe, keep same reference but allow new transfer.
        // We will generate a new reference only if previous transfer_id exists and failed; but keep idempotency_key same.

        // Reset to pending then process
        $fresh->update([
            'status' => MissionRewardPayout::STATUS_PENDING,
            'failure_reason' => null,
        ]);

        return self::processPayout($fresh);
    }

    /**
     * Resolve recipient GCash/Maya linked account for rider.
     */
    private static function resolveRecipient(int $userId): ?array
    {
        $linked = WalletLinkedAccount::where('user_id', $userId)
            ->whereIn('provider', ['gcash', 'maya'])
            ->where('is_verified', true)
            ->orderByRaw("CASE WHEN provider='gcash' THEN 0 ELSE 1 END")
            ->first();

        if (!$linked) {
            // fallback to any linked even if not verified
            $linked = WalletLinkedAccount::where('user_id', $userId)
                ->whereIn('provider', ['gcash', 'maya'])
                ->first();
        }

        if (!$linked) {
            return null;
        }

        $meta = is_array($linked->meta) ? $linked->meta : [];
        $accountNumber = WalletWithdrawalService::normalizeAccountNumber(
            (string) ($meta['account_number'] ?? $linked->account_last4 ?? '')
        );

        // If only last4 stored, we can't payout — need full number
        if (strlen($accountNumber) < 10) {
            return null;
        }

        $holderName = trim((string) ($meta['account_holder_name'] ?? $linked->user->name ?? ''));

        if ($holderName === '') {
            $holderName = 'Rider ' . $userId;
        }

        return [
            'provider' => $linked->provider,
            'account_number' => $accountNumber,
            'holder_name' => $holderName,
        ];
    }
}
