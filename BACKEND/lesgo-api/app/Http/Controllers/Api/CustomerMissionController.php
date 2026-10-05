<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CustomerMission;
use App\Models\MissionTemplate;
use App\Models\Order;
use App\Models\RatingReview;
use App\Models\User;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;

class CustomerMissionController extends Controller
{
    /**
     * Get customer's missions for today
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return $this->error('Unauthorized', 401);
            }

            $today = now()->toDateString();

            // Get or create missions for today
            $missions = $this->getOrCreateDailyMissions($user, $today);

            // Update progress for all missions
            foreach ($missions as $mission) {
                $this->updateMissionProgress($mission, $user, $today);
            }

            // Reload missions to get updated progress
            $missions = CustomerMission::where('user_id', $user->id)
                ->where('mission_date', $today)
                ->orderBy('id')
                ->get();

            return $this->success($missions, 'Missions retrieved successfully');
        } catch (\Exception $e) {
            return $this->error('Failed to retrieve missions: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Claim mission reward
     */
    public function claim(Request $request, CustomerMission $mission): JsonResponse
    {
        try {
            $user = Auth::user();
            if (!$user || $mission->user_id !== $user->id) {
                return $this->error('Unauthorized', 401);
            }

            $result = \Illuminate\Support\Facades\DB::transaction(function () use ($mission, $user) {
                $lockedMission = CustomerMission::lockForUpdate()->find($mission->id);
                if (!$lockedMission) {
                    throw new \RuntimeException('Mission not found');
                }

                // Legacy completion flags came from client-reported follows or
                // shares. They are not trusted evidence, even before a refresh.
                if ($lockedMission->mission_type === 'social_follow') {
                    throw new \RuntimeException('Social follow rewards are paused until follow verification is available.');
                }

                if (!$lockedMission->is_completed) {
                    throw new \RuntimeException('Mission not completed yet');
                }

                if ($lockedMission->reward_claimed) {
                    throw new \RuntimeException('Reward already claimed');
                }

                $lockedMission->update([
                    'reward_claimed' => true,
                    'claimed_at' => now(),
                ]);

                if ($lockedMission->reward_type === 'voucher' && (float) $lockedMission->reward_value > 0) {
                    WalletService::credit(
                        $user,
                        (float) $lockedMission->reward_value,
                        'Mission reward: ' . $lockedMission->title,
                        'customer_mission',
                        $lockedMission->id
                    );
                }

                return $lockedMission->fresh();
            });

            return $this->success($result, 'Reward claimed successfully');
        } catch (\RuntimeException $e) {
            $msg = $e->getMessage();
            $code = $msg === 'Mission not found' ? 404 : 400;
            return $this->error($msg, $code);
        } catch (\Exception $e) {
            return $this->error('Failed to claim reward: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Record manual progress for app_review / social_follow missions.
     * Rate-limited: only one completion per mission per user (already enforced by DB unique).
     */
    public function recordProgress(Request $request, CustomerMission $mission): JsonResponse
    {
        $user = $request->user();
        if (!$user || (int) $mission->user_id !== (int) $user->id) {
            return $this->error('Unauthorized', 401);
        }

        if (!in_array($mission->mission_type, ['app_review', 'social_follow'], true)) {
            return $this->error('This mission tracks progress automatically.', 422);
        }

        if ($mission->mission_type === 'social_follow') {
            return $this->error('Social follow rewards are paused until follow verification is available.', 422);
        }

        // Prevent re-completing an already completed mission
        if ($mission->is_completed) {
            return $this->error('Mission already completed.', 400);
        }

        // Verify actual proof exists before allowing manual completion
        $hasProof = false;
        if ($mission->mission_type === 'app_review') {
            $hasProof = RatingReview::where('user_id', $user->id)->exists();
            if (!$hasProof) {
                return $this->error('Please leave a review first.', 422);
            }
        }

        $mission->update([
            'current_progress' => $mission->goal_target,
            'is_completed'     => true,
            'completed_at'     => $mission->completed_at ?? now(),
        ]);

        return $this->success($mission->fresh(), 'Mission progress recorded');
    }

    /**
     * Get or create daily missions for a user
     * Now DB-driven via mission_templates (target_audience=customer) with fallback to hardcoded.
     */
    private function getOrCreateDailyMissions(User $user, string $date): array
    {
        $missions = [];

        $templates = collect();

        try {
            if (Schema::hasTable('mission_templates')) {
                $templates = MissionTemplate::where('is_active', true)
                    ->where('target_audience', 'customer')
                    ->where('type', 'daily')
                    ->get();
            }
        } catch (\Throwable $e) {
            $templates = collect();
        }

        // Fallback to hardcoded only if table never seeded (backward compatibility), not when admin intentionally disabled all
        if ($templates->isEmpty()) {
            $totalExists = false;
            try {
                if (Schema::hasTable('mission_templates')) {
                    $totalExists = MissionTemplate::where('target_audience', 'customer')->exists();
                }
            } catch (\Throwable $e) {}
            if (!$totalExists) {
                $templates = collect([
                    ['goal_type' => 'leseat_order', 'title' => 'Book 1 LesEat today', 'description' => 'Order food from any restaurant', 'goal_target' => 1, 'reward_amount' => 50.00, 'service_code' => null],
                    ['goal_type' => 'friend_referral', 'title' => 'Refer 1 friend', 'description' => 'Invite a friend to join LesGo', 'goal_target' => 1, 'reward_amount' => 100.00, 'service_code' => null],
                    ['goal_type' => 'app_review', 'title' => 'Leave us a review', 'description' => 'Rate our app on the store', 'goal_target' => 1, 'reward_amount' => 25.00, 'service_code' => null],
                    ['goal_type' => 'social_follow', 'title' => 'Like our FB page', 'description' => 'Follow us on social media', 'goal_target' => 1, 'reward_amount' => 25.00, 'service_code' => null],
                    ['goal_type' => 'lesride_orders', 'title' => 'Book 5 LesRide', 'description' => 'Complete 5 ride bookings', 'goal_target' => 5, 'reward_amount' => 200.00, 'service_code' => null],
                ])->map(fn($a) => (object) $a);
            }
        }

        foreach ($templates as $template) {
            $missionType = $template->goal_type ?? $template->mission_type ?? 'custom';
            $title = $template->title;
            $description = $template->description;
            $goalTarget = $template->goal_target;
            $rewardValue = $template->reward_amount ?? $template->reward_value ?? 0;
            $templateId = $template->id ?? null;

            $mission = CustomerMission::firstOrCreate(
                [
                    'user_id' => $user->id,
                    'mission_type' => $missionType,
                    'mission_date' => $date,
                ],
                [
                    'mission_template_id' => $templateId,
                    'title' => $title,
                    'description' => $description,
                    'current_progress' => 0,
                    'goal_target' => $goalTarget,
                    'is_completed' => false,
                    'reward_type' => 'voucher',
                    'reward_value' => $rewardValue,
                    'reward_claimed' => false,
                ]
            );

            // Keep template link and sync only if not completed nor claimed (prevent retroactive reward inflation)
            if ($mission->wasRecentlyCreated === false && !$mission->is_completed && !$mission->reward_claimed) {
                $needsUpdate = $mission->title !== $title || (float) $mission->reward_value !== (float) $rewardValue || (int) $mission->goal_target !== (int) $goalTarget || $mission->mission_template_id != $templateId;
                if ($needsUpdate) {
                    $mission->update([
                        'mission_template_id' => $templateId,
                        'title' => $title,
                        'description' => $description,
                        'goal_target' => $goalTarget,
                        'reward_value' => $rewardValue,
                    ]);
                }
            } elseif ($mission->mission_template_id === null && $templateId !== null) {
                $mission->update(['mission_template_id' => $templateId]);
            }

            $missions[] = $mission;
        }

        return $missions;
    }

    /**
     * Update mission progress based on user activities
     */
    private function updateMissionProgress(CustomerMission $mission, User $user, string $date): void
    {
        if ($mission->mission_type === 'social_follow') {
            // Keep paid history intact; invalidate unclaimed legacy completions.
            // No trusted social-follow verifier is currently integrated.
            if (!$mission->reward_claimed) {
                $mission->update([
                    'current_progress' => 0,
                    'is_completed' => false,
                    'completed_at' => null,
                ]);
            }
            return;
        }

        $progress = 0;

        switch ($mission->mission_type) {
            case 'leseat_order':
                $serviceId = \App\Models\Service::where('code', 'LESEAT')->value('id') ?? 3;
                $progress = Order::where('customer_id', $user->id)
                    ->where('service_id', $serviceId)
                    ->where('status', 'completed')
                    ->whereDate('created_at', $date)
                    ->count();
                break;

            case 'lesride_orders':
                $serviceId = \App\Models\Service::where('code', 'LESRIDE')->value('id') ?? 2;
                $progress = Order::where('customer_id', $user->id)
                    ->where('service_id', $serviceId)
                    ->where('status', 'completed')
                    ->whereDate('created_at', $date)
                    ->count();
                break;

            case 'friend_referral':
            case 'refer_friend':
                if (empty($user->referral_code)) {
                    $progress = 0;
                } else {
                    $progress = User::where('referred_by', $user->referral_code)
                        ->whereDate('created_at', $date)
                        ->count();
                }
                break;

            case 'app_review':
            case 'get_rating':
                // Must be created today to count; do not preserve stale progress if review deleted
                $progress = RatingReview::where('user_id', $user->id)->whereDate('created_at', $date)->exists() ? 1 : 0;
                // For backward compat if legacy reviews have no date filter, also check existence but only if goal is 1
                if ($progress === 0 && RatingReview::where('user_id', $user->id)->exists() && $mission->goal_target === 1) {
                    // keep legacy behavior: any review counts, but do not auto-complete if deleted
                    $progress = 0;
                }
                break;

            case 'complete_orders':
                $progress = Order::where('customer_id', $user->id)
                    ->where('status', 'completed')
                    ->whereDate('created_at', $date)
                    ->count();
                break;

            case 'specific_service':
                $template = $mission->missionTemplate;
                if (!$template && Schema::hasTable('mission_templates')) {
                    try {
                        $template = MissionTemplate::where('goal_type', $mission->mission_type)
                            ->where('target_audience', 'customer')
                            ->first();
                    } catch (\Throwable $e) {}
                }
                $serviceCode = $template?->service_code;
                $query = Order::where('customer_id', $user->id)->where('status','completed')->whereDate('created_at',$date);
                if ($serviceCode) {
                    $query->whereHas('service', fn($q) => $q->where('code', $serviceCode));
                }
                $progress = $query->count();
                break;

            default:
                \Illuminate\Support\Facades\Log::warning('Unknown customer mission_type', ['mission_id' => $mission->id, 'type' => $mission->mission_type]);
                $progress = Order::where('customer_id', $user->id)
                    ->where('status', 'completed')
                    ->whereDate('created_at', $date)
                    ->count();
                break;
        }

        // Update progress and completion status
        $isCompleted = $progress >= $mission->goal_target;
        
        $mission->update([
            'current_progress' => $progress,
            'is_completed' => $isCompleted,
            'completed_at' => $isCompleted && !$mission->completed_at ? now() : $mission->completed_at,
        ]);
    }
}
