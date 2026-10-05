<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\MissionRewardPayout;
use App\Services\MissionRewardPayoutService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MissionRewardPayoutAdminController extends Controller
{
    /**
     * Admin monitor: list all mission reward reimbursements with filters.
     */
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'status' => 'nullable|in:pending,processing,successful,failed',
            'search' => 'nullable|string|max:100',
            'per_page' => 'nullable|integer|min:1|max:100',
            'mission_template_id' => 'nullable|integer|exists:mission_templates,id',
            'rider_user_id' => 'nullable|integer|exists:users,id',
        ]);

        $query = MissionRewardPayout::with(['rider:id,name,email', 'missionTemplate:id,title', 'driverProfile:id,user_id', 'mission:id,mission_date,is_completed,reward_claimed']);

        if (!empty($validated['status'])) {
            $query->where('status', $validated['status']);
        }
        if (!empty($validated['mission_template_id'])) {
            $query->where('mission_template_id', $validated['mission_template_id']);
        }
        if (!empty($validated['rider_user_id'])) {
            $query->where('rider_user_id', $validated['rider_user_id']);
        }
        if (!empty($validated['search'])) {
            $search = $validated['search'];
            $query->where(function ($q) use ($search) {
                $q->where('paymongo_reference', 'like', "%{$search}%")
                  ->orWhere('paymongo_transfer_id', 'like', "%{$search}%")
                  ->orWhereHas('rider', fn($qq) => $qq->where('name', 'like', "%{$search}%")->orWhere('email', 'like', "%{$search}%"));
            });
        }

        $perPage = (int) ($validated['per_page'] ?? 20);
        $payouts = $query->latest()->paginate($perPage);

        // Add summary counts
        $summary = [
            'total' => MissionRewardPayout::count(),
            'pending' => MissionRewardPayout::where('status', 'pending')->count(),
            'processing' => MissionRewardPayout::where('status', 'processing')->count(),
            'successful' => MissionRewardPayout::where('status', 'successful')->count(),
            'failed' => MissionRewardPayout::where('status', 'failed')->count(),
            'total_amount_pending' => MissionRewardPayout::whereIn('status', ['pending','processing'])->sum('reward_amount'),
            'total_amount_successful' => MissionRewardPayout::where('status', 'successful')->sum('reward_amount'),
        ];

        return $this->success([
            'payouts' => $payouts,
            'summary' => $summary,
        ], 'Mission reward payouts retrieved');
    }

    public function show(MissionRewardPayout $missionRewardPayout): JsonResponse
    {
        $missionRewardPayout->load(['rider:id,name,email,phone_number', 'mission', 'missionTemplate', 'driverProfile']);

        return $this->success($missionRewardPayout, 'Payout retrieved');
    }

    /**
     * Retry a failed payout — safe and idempotent (does not create duplicate PayMongo transfer if already processed).
     */
    public function retry(Request $request, MissionRewardPayout $missionRewardPayout): JsonResponse
    {
        if (!$missionRewardPayout->canRetry()) {
            return $this->error('Only failed payouts can be retried. Current status: ' . $missionRewardPayout->status, 422);
        }

        try {
            $retried = MissionRewardPayoutService::retryPayout($missionRewardPayout);
            return $this->success($retried->fresh(), 'Payout retry initiated via PayMongo');
        } catch (\RuntimeException $e) {
            return $this->error($e->getMessage(), 422);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('Admin retry mission payout failed', [
                'payout_id' => $missionRewardPayout->id,
                'error' => $e->getMessage(),
            ]);
            return $this->error('Retry failed: ' . $e->getMessage(), 502);
        }
    }

    /**
     * Stats overview for admin dashboard widget.
     */
    public function stats(): JsonResponse
    {
        return $this->success([
            'total' => MissionRewardPayout::count(),
            'pending' => MissionRewardPayout::where('status', 'pending')->count(),
            'processing' => MissionRewardPayout::where('status', 'processing')->count(),
            'successful' => MissionRewardPayout::where('status', 'successful')->count(),
            'failed' => MissionRewardPayout::where('status', 'failed')->count(),
        ], 'Stats retrieved');
    }
}
