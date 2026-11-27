<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\MerchantWithdrawalRequest;
use App\Services\MerchantWithdrawalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Admin processing of merchant withdrawal requests: approve, complete, reject
 * (refunds the reserved funds) or mark failed (also refunds).
 */
class MerchantWithdrawalAdminController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = MerchantWithdrawalRequest::query()
            ->with(['partner:id,name,user_id', 'user:id,name,email'])
            ->orderByDesc('id');

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        return $this->success($query->paginate($request->integer('per_page', 20)));
    }

    public function approve(Request $request, MerchantWithdrawalRequest $withdrawal): JsonResponse
    {
        $data = $request->validate(['notes' => ['nullable', 'string', 'max:1000']]);

        return $this->run(fn () => MerchantWithdrawalService::approve($withdrawal, $request->user(), $data['notes'] ?? null), 'Withdrawal approved');
    }

    public function complete(Request $request, MerchantWithdrawalRequest $withdrawal): JsonResponse
    {
        $data = $request->validate(['notes' => ['nullable', 'string', 'max:1000']]);

        return $this->run(fn () => MerchantWithdrawalService::complete($withdrawal, $request->user(), $data['notes'] ?? null), 'Withdrawal completed');
    }

    public function reject(Request $request, MerchantWithdrawalRequest $withdrawal): JsonResponse
    {
        $data = $request->validate(['reason' => ['required', 'string', 'max:500']]);

        return $this->run(fn () => MerchantWithdrawalService::reject($withdrawal, $request->user(), $data['reason']), 'Withdrawal rejected and funds returned');
    }

    public function fail(Request $request, MerchantWithdrawalRequest $withdrawal): JsonResponse
    {
        $data = $request->validate(['reason' => ['nullable', 'string', 'max:500']]);

        return $this->run(fn () => MerchantWithdrawalService::fail($withdrawal, $request->user(), $data['reason'] ?? null), 'Withdrawal marked failed and funds returned');
    }

    private function run(\Closure $action, string $message): JsonResponse
    {
        try {
            return $this->success($action(), $message);
        } catch (\RuntimeException $e) {
            return $this->error($e->getMessage(), 422);
        }
    }
}
