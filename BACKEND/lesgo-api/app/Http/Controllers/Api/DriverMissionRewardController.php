<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MissionRewardPayout;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DriverMissionRewardController extends Controller
{
    /**
     * Rider: list own mission reward payouts.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user || !$user->isDriver()) {
            return response()->json(['success' => false, 'message' => 'User is not a driver'], 403);
        }

        $payouts = MissionRewardPayout::where('rider_user_id', $user->id)
            ->with(['missionTemplate:id,title', 'mission:id,mission_date'])
            ->orderByDesc('id')
            ->paginate(20);

        return $this->success($payouts, 'Rewards retrieved');
    }

    public function show(Request $request, MissionRewardPayout $payout): JsonResponse
    {
        $user = $request->user();
        if ((int) $payout->rider_user_id !== (int) $user->id && !$user->isAdmin()) {
            return $this->error('Forbidden', 403);
        }

        $payout->load(['mission', 'missionTemplate', 'driverProfile']);

        // Do not expose PayMongo secret keys; only reference IDs
        $data = $payout->toArray();
        unset($data['paymongo_payload']['secret'], $data['paymongo_response']['secret']);

        return $this->success($payout, 'Reward payout retrieved');
    }
}
