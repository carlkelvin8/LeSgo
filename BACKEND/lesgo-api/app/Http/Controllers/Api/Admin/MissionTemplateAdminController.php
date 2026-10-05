<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\MissionTemplate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MissionTemplateAdminController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:sanctum');
        $this->middleware(function ($request, $next) {
            if (!$request->user() || !$request->user()->isAdmin()) {
                return response()->json(['success' => false, 'message' => 'Forbidden'], 403);
            }
            return $next($request);
        });
    }

    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'search' => 'nullable|string|max:100',
            'target_audience' => 'nullable|in:driver,merchant,customer',
            'type' => 'nullable|in:daily,weekly,monthly,one_time',
            'is_active' => 'nullable|in:0,1,true,false',
            'per_page' => 'nullable|integer|min:1|max:100',
        ]);

        $query = MissionTemplate::query();

        if (!empty($validated['search'])) {
            $search = $validated['search'];
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }
        if (!empty($validated['target_audience'])) {
            $query->where('target_audience', $validated['target_audience']);
        }
        if (!empty($validated['type'])) {
            $query->where('type', $validated['type']);
        }
        if (isset($validated['is_active'])) {
            $isActive = in_array($validated['is_active'], ['1','true',1,true], true);
            $query->where('is_active', $isActive);
        }

        $perPage = (int) ($validated['per_page'] ?? 20);
        $templates = $query->latest()->paginate($perPage);

        return $this->success($templates, 'Mission templates retrieved successfully');
    }

    public function show(MissionTemplate $missionTemplate): JsonResponse
    {
        return $this->success($missionTemplate, 'Mission template retrieved successfully');
    }

    private const ALLOWED_GOAL_TYPES = ['complete_orders','specific_service','get_rating','refer_friend','leseat_order','lesride_orders','friend_referral','app_review','social_follow'];
    private const ALLOWED_CURRENCIES = ['PHP'];

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'type' => 'required|in:daily,weekly,monthly,one_time',
            'target_audience' => 'required|in:driver,merchant,customer',
            'goal_type' => ['required','string','max:50','in:'.implode(',', self::ALLOWED_GOAL_TYPES)],
            'goal_target' => 'required|integer|min:1',
            'reward_amount' => 'required|numeric|min:0',
            'reward_currency' => ['nullable','string','max:10','in:'.implode(',', self::ALLOWED_CURRENCIES)],
            'service_code' => 'nullable|string|max:50|exists:services,code',
            'is_active' => 'sometimes|boolean',
        ]);

        // require service_code when specific_service
        if ($validated['goal_type'] === 'specific_service' && empty($validated['service_code'])) {
            return $this->error('service_code is required when goal_type is specific_service', 422);
        }

        $validated['reward_currency'] = $validated['reward_currency'] ?? 'PHP';
        $validated['is_active'] = $request->boolean('is_active', true);

        $template = MissionTemplate::create($validated);

        return $this->created($template, 'Mission template created successfully');
    }

    public function update(Request $request, MissionTemplate $missionTemplate): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'type' => 'required|in:daily,weekly,monthly,one_time',
            'target_audience' => 'required|in:driver,merchant,customer',
            'goal_type' => ['required','string','max:50','in:'.implode(',', self::ALLOWED_GOAL_TYPES)],
            'goal_target' => 'required|integer|min:1',
            'reward_amount' => 'required|numeric|min:0',
            'reward_currency' => ['nullable','string','max:10','in:'.implode(',', self::ALLOWED_CURRENCIES)],
            'service_code' => 'nullable|string|max:50|exists:services,code',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validated['goal_type'] === 'specific_service' && empty($validated['service_code'])) {
            return $this->error('service_code is required when goal_type is specific_service', 422);
        }

        if ($request->has('is_active')) {
            $validated['is_active'] = $request->boolean('is_active');
        }

        $missionTemplate->update($validated);

        return $this->success($missionTemplate->fresh(), 'Mission template updated successfully');
    }

    public function destroy(MissionTemplate $missionTemplate): JsonResponse
    {
        $missionTemplate->delete();
        return $this->message('Mission template deleted successfully');
    }

    public function toggle(MissionTemplate $missionTemplate): JsonResponse
    {
        $missionTemplate->update(['is_active' => !$missionTemplate->is_active]);
        $status = $missionTemplate->is_active ? 'activated' : 'deactivated';
        return $this->success($missionTemplate->fresh(), "Mission template {$status} successfully");
    }
}
