<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Voucher;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VoucherAdminController extends Controller
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
            'is_active' => 'nullable|in:0,1,true,false',
            'type' => 'nullable|in:percentage,fixed,free_delivery,buy_one_get_one',
            'per_page' => 'nullable|integer|min:1|max:100',
        ]);

        $query = Voucher::query();

        if (!empty($validated['search'])) {
            $search = str_replace(['\\','%','_'], ['\\\\','\%','\_'], $validated['search']);
            $query->where(function ($q) use ($search) {
                $q->where('code', 'like', "%{$search}%")
                  ->orWhere('title', 'like', "%{$search}%");
            });
        }
        if (isset($validated['is_active'])) {
            $isActive = in_array($validated['is_active'], ['1','true',1,true], true);
            $query->where('is_active', $isActive);
        }
        if (!empty($validated['type'])) {
            $query->where('type', $validated['type']);
        }

        $perPage = (int) ($validated['per_page'] ?? 20);
        $vouchers = $query->latest()->paginate($perPage);

        // Append used_count - case-insensitive, avoid N+1 via single query batch
        $codes = $vouchers->getCollection()->pluck('code')->map(fn($c)=>strtoupper($c))->toArray();
        $counts = [];
        if (!empty($codes)) {
            $placeholders = implode(',', array_fill(0, count($codes), '?'));
            $rows = \Illuminate\Support\Facades\DB::select("SELECT UPPER(voucher_code) as code, COUNT(*) as cnt FROM orders WHERE UPPER(voucher_code) IN ($placeholders) AND status NOT IN ('cancelled','failed') GROUP BY UPPER(voucher_code)", $codes);
            foreach ($rows as $r) { $counts[strtoupper($r->code)] = (int) $r->cnt; }
        }
        $vouchers->getCollection()->transform(function ($v) use ($counts) {
            $v->used_count = $counts[strtoupper($v->code)] ?? 0;
            return $v;
        });

        return $this->success($vouchers, 'Vouchers retrieved successfully');
    }

    public function show(Voucher $voucher): JsonResponse
    {
        $voucher->used_count = \App\Models\Order::whereRaw('UPPER(voucher_code) = ?', [strtoupper($voucher->code)])->whereNotIn('status', ['cancelled','failed'])->count();
        return $this->success($voucher, 'Voucher retrieved successfully');
    }

    public function store(Request $request): JsonResponse
    {
        // Normalize code before validation to enforce case-insensitive unique
        $request->merge(['code' => strtoupper(trim($request->input('code','')))]);
        $validated = $request->validate([
            'code' => 'required|string|max:50|unique:vouchers,code',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'discount_text' => 'nullable|string|max:100',
            'min_order' => 'nullable|string|max:100',
            'type' => 'required|in:percentage,fixed,free_delivery,buy_one_get_one',
            'value' => 'required|numeric|min:0',
            'max_discount' => 'nullable|numeric|min:0',
            'min_order_value' => 'required|numeric|min:0',
            'max_uses' => 'nullable|integer|min:1',
            'expires_at' => 'nullable|date|after_or_equal:today',
            'user_restrictions' => 'nullable|array',
            'user_restrictions.new_users_only' => 'nullable|boolean',
            'user_restrictions.max_uses_per_user' => 'nullable|integer|min:1',
            'applicable_services' => 'nullable|array',
            'applicable_services.*' => 'integer|exists:services,id',
            'is_active' => 'sometimes|boolean',
        ]);

        $validated['code'] = strtoupper(trim($validated['code']));
        $validated['is_active'] = $request->boolean('is_active', true);

        $voucher = Voucher::create($validated);

        return $this->created($voucher, 'Voucher created successfully');
    }

    public function update(Request $request, Voucher $voucher): JsonResponse
    {
        $request->merge(['code' => strtoupper(trim($request->input('code','')))]);
        $validated = $request->validate([
            'code' => 'required|string|max:50|unique:vouchers,code,' . $voucher->id,
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'discount_text' => 'nullable|string|max:100',
            'min_order' => 'nullable|string|max:100',
            'type' => 'required|in:percentage,fixed,free_delivery,buy_one_get_one',
            'value' => 'required|numeric|min:0',
            'max_discount' => 'nullable|numeric|min:0',
            'min_order_value' => 'required|numeric|min:0',
            'max_uses' => 'nullable|integer|min:1',
            'expires_at' => 'nullable|date|after_or_equal:today',
            'user_restrictions' => 'nullable|array',
            'user_restrictions.new_users_only' => 'nullable|boolean',
            'user_restrictions.max_uses_per_user' => 'nullable|integer|min:1',
            'applicable_services' => 'nullable|array',
            'applicable_services.*' => 'integer|exists:services,id',
            'is_active' => 'sometimes|boolean',
        ]);

        $validated['code'] = strtoupper(trim($validated['code']));
        if ($request->has('is_active')) {
            $validated['is_active'] = $request->boolean('is_active');
        }

        $voucher->update($validated);

        return $this->success($voucher->fresh(), 'Voucher updated successfully');
    }

    public function destroy(Voucher $voucher): JsonResponse
    {
        $voucher->delete();
        return $this->message('Voucher deleted successfully');
    }

    public function toggle(Voucher $voucher): JsonResponse
    {
        $voucher->update(['is_active' => !$voucher->is_active]);
        $status = $voucher->is_active ? 'activated' : 'deactivated';
        return $this->success($voucher->fresh(), "Voucher {$status} successfully");
    }
}
