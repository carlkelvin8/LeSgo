<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DriverMission;
use App\Models\MissionRewardPayout;
use App\Models\MissionTemplate;
use App\Services\MissionRewardPayoutService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DriverMissionController extends Controller
{
    /**
     * Get driver's missions for today
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        
        if (!$user->isDriver() || !$user->driverProfile) {
            return response()->json([
                'success' => false,
                'message' => 'User is not a driver',
            ], 403);
        }

        $driverProfileId = $user->driverProfile->id;
        $today = now()->toDateString();

        // Get all active mission templates for drivers
        $templates = MissionTemplate::where('is_active', true)
            ->where('target_audience', 'driver')
            ->where('type', 'daily')
            ->get();

        // Get or create driver missions for today
        $missions = [];
        foreach ($templates as $template) {
            $driverMission = DriverMission::firstOrCreate(
                [
                    'driver_profile_id' => $driverProfileId,
                    'mission_template_id' => $template->id,
                    'mission_date' => $today,
                ],
                [
                    'current_progress' => 0,
                    'goal_target' => $template->goal_target,
                    'is_completed' => false,
                ]
            );

            // Update progress based on actual data
            $this->updateMissionProgress($driverMission, $template, $driverProfileId, $today);

            $missions[] = [
                'id' => $driverMission->id,
                'title' => $template->title,
                'description' => $template->description,
                'reward' => $template->reward_currency . ' ' . number_format($template->reward_amount, 0),
                'reward_amount' => (float) $template->reward_amount,
                'current_progress' => $driverMission->current_progress,
                'goal_target' => $driverMission->goal_target,
                'progress' => $driverMission->progress_percentage,
                'is_completed' => $driverMission->is_completed,
                'reward_claimed' => $driverMission->reward_claimed,
            ];
        }

        return response()->json([
            'success' => true,
            'missions' => $missions,
        ]);
    }

    /**
     * Claim mission reward — now PayMongo-backed with validation + idempotency.
     * Flow: validate mission -> create MissionRewardPayout (pending) -> initiate PayMongo transfer (processing)
     * Wallet is credited ONLY after PayMongo webhook confirms success.
     */
    public function claim(Request $request, int $missionId): JsonResponse
    {
        $user = $request->user();

        if (!$user->isDriver() || !$user->driverProfile) {
            return response()->json([
                'success' => false,
                'message' => 'User is not a driver',
            ], 403);
        }

        // Header-based idempotency (optional): client may send Idempotency-Key to guard retries
        $idempotencyKeyHeader = $request->header('Idempotency-Key');

        try {
            $driverMission = DriverMission::where('id', $missionId)
                ->where('driver_profile_id', $user->driverProfile->id)
                ->first();

            if (!$driverMission) {
                return response()->json(['success' => false, 'message' => 'Mission not found'], 404);
            }

            // Validate and create payout record (idempotent)
            $payout = MissionRewardPayoutService::validateAndCreatePayout($driverMission, $user);

            // Duplicate protection: if payout already exists and is not failed, return existing status
            if ($payout->isSuccessful()) {
                return response()->json([
                    'success' => true,
                    'message' => 'Reward already reimbursed',
                    'data' => $this->formatPayoutResponse($payout),
                ]);
            }

            if ($payout->isProcessing()) {
                return response()->json([
                    'success' => true,
                    'message' => 'Reward reimbursement is processing via PayMongo. Will be credited after confirmation.',
                    'data' => $this->formatPayoutResponse($payout),
                ]);
            }

            if ($payout->isPending() && $payout->paymongo_transfer_id) {
                // Pending but already has a transfer — treat as processing
                return response()->json([
                    'success' => true,
                    'message' => 'Reward reimbursement pending PayMongo confirmation.',
                    'data' => $this->formatPayoutResponse($payout),
                ]);
            }

            // Try to process via PayMongo
            try {
                $processed = MissionRewardPayoutService::processPayout($payout);

                return response()->json([
                    'success' => true,
                    'message' => 'Reward validated. PayMongo reimbursement processing — wallet will be credited after webhook confirmation.',
                    'data' => $this->formatPayoutResponse($processed),
                ], 202);
            } catch (\RuntimeException $e) {
                // Check if payout was marked pending due to missing linked account
                $fresh = $payout->fresh();
                if ($fresh && $fresh->status === MissionRewardPayout::STATUS_PENDING) {
                    return response()->json([
                        'success' => false,
                        'message' => $e->getMessage(),
                        'data' => $this->formatPayoutResponse($fresh),
                    ], 422);
                }
                // Otherwise failed
                $fresh = $payout->fresh();
                return response()->json([
                    'success' => false,
                    'message' => $e->getMessage(),
                    'data' => $fresh ? $this->formatPayoutResponse($fresh) : null,
                ], 502);
            }
        } catch (\RuntimeException $e) {
            $msg = $e->getMessage();
            $code = $msg === 'Mission not found' ? 404 : 400;
            return response()->json(['success' => false, 'message' => $msg], $code);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('Driver mission claim failed', [
                'mission_id' => $missionId,
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);
            return response()->json(['success' => false, 'message' => 'Failed to claim reward: ' . $e->getMessage()], 500);
        }
    }

    private function formatPayoutResponse(MissionRewardPayout $payout): array
    {
        return [
            'payout_id' => $payout->id,
            'mission_id' => $payout->mission_id,
            'rider_user_id' => $payout->rider_user_id,
            'reward_amount' => (float) $payout->reward_amount,
            'reward_currency' => $payout->reward_currency,
            'paymongo_reference' => $payout->paymongo_reference,
            'paymongo_transfer_id' => $payout->paymongo_transfer_id,
            'provider' => $payout->provider,
            'status' => $payout->status,
            'failure_reason' => $payout->failure_reason,
            'requested_at' => $payout->requested_at?->toIso8601String(),
            'processed_at' => $payout->processed_at?->toIso8601String(),
        ];
    }

    /**
     * Update mission progress based on actual data
     */
    private function updateMissionProgress(DriverMission $mission, MissionTemplate $template, int $driverProfileId, string $date): void
    {
        $progress = 0;

        switch ($template->goal_type) {
            case 'complete_orders':
                // Count completed orders for today
                $progress = \App\Models\Order::whereHas('driverProfile', function ($q) use ($driverProfileId) {
                    $q->where('id', $driverProfileId);
                })
                ->where('status', 'completed')
                ->whereDate('updated_at', $date)
                ->count();
                break;

            case 'specific_service':
                // Count completed orders for specific service
                $progress = \App\Models\Order::whereHas('driverProfile', function ($q) use ($driverProfileId) {
                    $q->where('id', $driverProfileId);
                })
                ->whereHas('service', function ($q) use ($template) {
                    $q->where('code', $template->service_code);
                })
                ->where('status', 'completed')
                ->whereDate('updated_at', $date)
                ->count();
                break;

            case 'get_rating':
                // Check if driver got a 5-star rating today
                $hasRating = \App\Models\RatingReview::where('driver_id', $driverProfileId)
                    ->where('overall_rating', '>=', $template->goal_target)
                    ->whereDate('created_at', $date)
                    ->exists();
                $progress = $hasRating ? 1 : 0;
                break;

            case 'refer_friend':
                // Count referrals today (users who used driver's referral code)
                $user = \App\Models\User::whereHas('driverProfile', function ($q) use ($driverProfileId) {
                    $q->where('id', $driverProfileId);
                })->first();
                
                if ($user) {
                    $progress = \App\Models\User::where('referred_by', $user->referral_code)
                        ->whereDate('created_at', $date)
                        ->count();
                }
                break;
        }

        // Update progress
        $isCompleted = $progress >= $template->goal_target;
        $mission->update([
            'current_progress' => $progress,
            'is_completed' => $isCompleted,
            'completed_at' => $isCompleted && !$mission->is_completed ? now() : $mission->completed_at,
        ]);
    }
}
