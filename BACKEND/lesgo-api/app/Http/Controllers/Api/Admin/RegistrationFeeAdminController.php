<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\RegistrationFeePayment;
use App\Services\RegistrationFeeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RegistrationFeeAdminController extends Controller
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
            'account_type' => 'nullable|in:rider,merchant',
            'payment_status' => 'nullable|in:unpaid,pending,paid,waived,failed,expired',
            'application_status' => 'nullable|in:pending,approved,rejected',
            'is_active' => 'nullable|in:0,1,true,false',
            'search' => 'nullable|string|max:100',
            'per_page' => 'nullable|integer|min:1|max:100',
        ]);

        $query = RegistrationFeePayment::with(['user:id,name,email,phone_number,created_at', 'approver:id,name', 'waivedBy:id,name']);

        if (!empty($validated['account_type'])) {
            $query->where('account_type', $validated['account_type']);
        }
        if (!empty($validated['payment_status'])) {
            $query->where('payment_status', $validated['payment_status']);
        }
        if (!empty($validated['application_status'])) {
            $query->where('application_status', $validated['application_status']);
        }
        if (isset($validated['is_active']) && $validated['is_active'] !== '') {
            $isActive = in_array($validated['is_active'], ['1', 'true', 1, true], true);
            $query->where('is_active', $isActive);
        }
        if (!empty($validated['search'])) {
            $search = $validated['search'];
            $query->where(function ($q) use ($search) {
                $q->where('paymongo_reference', 'like', "%{$search}%")
                  ->orWhere('paymongo_checkout_id', 'like', "%{$search}%")
                  ->orWhereHas('user', fn($qq) => $qq->where('name', 'like', "%{$search}%")->orWhere('email', 'like', "%{$search}%"));
            });
        }

        $perPage = (int) ($validated['per_page'] ?? 20);
        $payments = $query->latest()->paginate($perPage);

        $summary = [
            'total' => RegistrationFeePayment::count(),
            'rider_total' => RegistrationFeePayment::where('account_type', 'rider')->count(),
            'merchant_total' => RegistrationFeePayment::where('account_type', 'merchant')->count(),
            'paid' => RegistrationFeePayment::where('payment_status', 'paid')->count(),
            'waived' => RegistrationFeePayment::where('payment_status', 'waived')->count(),
            'pending_payment' => RegistrationFeePayment::whereIn('payment_status', ['unpaid', 'pending'])->count(),
            'approved' => RegistrationFeePayment::where('application_status', 'approved')->count(),
            'pending_approval' => RegistrationFeePayment::where('application_status', 'pending')->count(),
            'active' => RegistrationFeePayment::where('is_active', true)->count(),
            'restricted' => RegistrationFeePayment::where('is_active', false)->count(),
        ];

        return $this->success(['payments' => $payments, 'summary' => $summary], 'Registration fees retrieved');
    }

    public function show(RegistrationFeePayment $registrationFee): JsonResponse
    {
        $registrationFee->load(['user', 'approver', 'waivedBy']);
        return $this->success($registrationFee, 'Registration fee retrieved');
    }

    public function approve(Request $request, RegistrationFeePayment $registrationFee): JsonResponse
    {
        if ($registrationFee->application_status === RegistrationFeePayment::APP_APPROVED) {
            return $this->error('Already approved', 422);
        }

        $wasActiveBefore = $registrationFee->is_active;
        $updated = RegistrationFeeService::approveApplication($registrationFee, $request->user());

        $msg = $updated->is_active
            ? 'Application approved – account activated (fee paid or waived + approved)'
            : 'Application approved – registration fee must still be paid or waived (account remains restricted)';

        if (!$updated->isFeeSatisfied() && $updated->is_active) {
            // Should never happen due to service logic, but guard
            return $this->error('Logic error: approved but fee unpaid should not activate', 500);
        }

        return $this->success($updated->fresh(), $msg);
    }

    public function waive(Request $request, RegistrationFeePayment $registrationFee): JsonResponse
    {
        $validated = $request->validate(['reason' => 'nullable|string|max:1000']);

        try {
            $updated = RegistrationFeeService::waiveFee($registrationFee, $request->user(), $validated['reason'] ?? null);
        } catch (\DomainException $e) {
            return $this->error($e->getMessage(), 422);
        }

        return $this->success($updated, $updated->is_active
            ? 'Registration fee waived by admin; approved account activated.'
            : 'Registration fee waived by admin; account remains restricted pending approval.');
    }

    public function reject(Request $request, RegistrationFeePayment $registrationFee): JsonResponse
    {
        $validated = $request->validate(['reason' => 'nullable|string|max:1000']);

        $updated = RegistrationFeeService::rejectApplication($registrationFee, $request->user(), $validated['reason'] ?? null);

        return $this->success($updated->fresh(), 'Application rejected – account remains restricted');
    }

    public function config(Request $request): JsonResponse
    {
        return $this->success([
            'rider_fee' => RegistrationFeeService::getFeeForType('rider'),
            'merchant_fee' => RegistrationFeeService::getFeeForType('merchant'),
            'enforce_from' => RegistrationFeeService::getEnforceFromDate(),
        ], 'Config retrieved');
    }

    public function updateConfig(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'rider_fee' => 'nullable|numeric|min:0|max:100000',
            'merchant_fee' => 'nullable|numeric|in:1000',
            'enforce_from' => 'nullable|date',
        ]);

        $adminId = (string) $request->user()->id;

        if (isset($validated['rider_fee'])) {
            \App\Services\RiderCommissionService::setPackagePrice('basic', (float) $validated['rider_fee'], $adminId);
        }
        if (isset($validated['merchant_fee'])) {
            \App\Models\SecuritySetting::setValue(RegistrationFeeService::SETTING_MERCHANT_FEE, number_format((float) $validated['merchant_fee'], 2, '.', ''), $adminId);
        }
        if (isset($validated['enforce_from'])) {
            \App\Models\SecuritySetting::setValue(RegistrationFeeService::SETTING_ENFORCE_FROM, $validated['enforce_from'], $adminId);
        }

        return $this->success([
            'rider_fee' => RegistrationFeeService::getFeeForType('rider'),
            'merchant_fee' => RegistrationFeeService::getFeeForType('merchant'),
            'enforce_from' => RegistrationFeeService::getEnforceFromDate(),
        ], 'Config updated');
    }
}
