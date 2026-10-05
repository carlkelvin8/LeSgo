<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MerchantWithdrawalRequest;
use App\Models\Partner;
use App\Models\User;
use App\Models\Wallet;
use App\Services\MerchantWithdrawalService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class MerchantWithdrawalController extends Controller
{
    /**
     * Resolve the partner (merchant) that the authenticated user belongs to.
     *
     * The merchant owner is a `partner_admin` (User::partner()); staff members
     * are `partner_staff` and reach the partner through their PartnerStaff row.
     */
    private function partnerFor(User $user): ?Partner
    {
        if ($user->isPartnerAdmin()) {
            return $user->partner;
        }

        if ($user->isPartnerStaff()) {
            return $user->partnerStaff?->partner;
        }

        return null;
    }

    /**
     * Whether the user may move money out of the partner wallet.
     *
     * Mirrors the app's MerchantStaffPermissions: owners always can, staff
     * admins always can, and other roles fall back to their role defaults
     * (cashier) unless explicit permissions were configured.
     */
    private function canManageWallet(User $user): bool
    {
        if ($user->isPartnerAdmin()) {
            return true;
        }

        if (! $user->isPartnerStaff()) {
            return false;
        }

        $staff = $user->partnerStaff;

        if (! $staff || ! $staff->is_active) {
            return false;
        }

        if ($staff->isAdmin()) {
            return true;
        }

        if (! empty($staff->permissions)) {
            return $staff->hasPermission('manage_wallet');
        }

        return $staff->isCashier();
    }

    private function forbidden(string $message)
    {
        return response()->json([
            'success' => false,
            'message' => $message,
        ], 403);
    }

    private function partnerMissing()
    {
        return response()->json([
            'success' => false,
            'message' => 'Partner profile not found.',
        ], 404);
    }

    /**
     * Get merchant's withdrawal requests
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $partner = $this->partnerFor($user);

            if (! $partner) {
                return $this->forbidden('Only merchants can access withdrawal requests.');
            }

            $query = MerchantWithdrawalRequest::where('partner_id', $partner->id)
                ->with(['user', 'wallet'])
                ->orderBy('created_at', 'desc');

            // Filter by status if provided
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Pagination
            $perPage = min((int) $request->get('per_page', 20), 100);
            $withdrawals = $query->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => $withdrawals,
            ]);
        } catch (\Exception $e) {
            Log::error('Withdrawal index error', [
                'error' => $e->getMessage(),
                'user_id' => $request->user()->id ?? null,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch withdrawal requests.',
            ], 500);
        }
    }

    /**
     * Create a new withdrawal request
     */
    public function store(Request $request)
    {
        $user = $request->user();
        $partner = $this->partnerFor($user);

        if (! $partner) {
            return $this->forbidden('Only merchants can create withdrawal requests.');
        }

        if (! $this->canManageWallet($user)) {
            return $this->forbidden('Your staff role cannot request withdrawals.');
        }

        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:100|max:999999.99',
            'payout_method' => 'required|in:gcash,maya,bank_transfer',
            'payout_account_number' => 'required|string|max:50',
            'payout_account_name' => 'required|string|max:100',
            'payout_bank_name' => 'required_if:payout_method,bank_transfer|nullable|string|max:100',
        ], [
            'amount.required' => 'Withdrawal amount is required.',
            'amount.min' => 'Minimum withdrawal amount is PHP 100.00.',
            'amount.max' => 'Maximum withdrawal amount is PHP 999,999.99.',
            'payout_method.required' => 'Please select a payout method.',
            'payout_method.in' => 'Invalid payout method selected.',
            'payout_account_number.required' => 'Account number is required.',
            'payout_account_name.required' => 'Account name is required.',
            'payout_bank_name.required_if' => 'Bank name is required for bank transfers.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $withdrawal = MerchantWithdrawalService::request($user, $partner, $validator->validated());
        } catch (\RuntimeException $e) {
            $wallet = Wallet::where('user_id', $partner->user_id)->first();

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'available_balance' => $wallet ? (float) $wallet->balance : 0,
                'pending_withdrawals' => $wallet ? $wallet->pendingWithdrawalAmount() : 0,
            ], 422);
        } catch (\Throwable $e) {
            Log::error('Withdrawal store error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => $user->id,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to create withdrawal request. Please try again.',
            ], 500);
        }

        Log::info('Withdrawal request created', [
            'withdrawal_id' => $withdrawal->id,
            'user_id' => $user->id,
            'partner_id' => $partner->id,
            'amount' => (float) $withdrawal->amount,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Withdrawal request submitted successfully. Please wait for admin approval.',
            'data' => $withdrawal,
        ], 201);
    }

    /**
     * Get a specific withdrawal request
     */
    public function show(Request $request, $id)
    {
        try {
            $user = $request->user();
            $partner = $this->partnerFor($user);

            if (! $partner) {
                return $this->partnerMissing();
            }

            $withdrawal = MerchantWithdrawalRequest::where('id', $id)
                ->where('partner_id', $partner->id)
                ->with(['user', 'wallet', 'partner', 'approver', 'processor'])
                ->first();

            if (! $withdrawal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Withdrawal request not found.',
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $withdrawal,
            ]);
        } catch (\Exception $e) {
            Log::error('Withdrawal show error', [
                'error' => $e->getMessage(),
                'withdrawal_id' => $id,
                'user_id' => $request->user()->id ?? null,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch withdrawal request.',
            ], 500);
        }
    }

    /**
     * Cancel a pending withdrawal request
     */
    public function cancel(Request $request, $id)
    {
        $user = $request->user();
        $partner = $this->partnerFor($user);

        if (! $partner) {
            return $this->partnerMissing();
        }

        if (! $this->canManageWallet($user)) {
            return $this->forbidden('Your staff role cannot cancel withdrawals.');
        }

        $withdrawal = MerchantWithdrawalRequest::where('id', $id)
            ->where('partner_id', $partner->id)
            ->first();

        if (! $withdrawal) {
            return response()->json([
                'success' => false,
                'message' => 'Withdrawal request not found.',
            ], 404);
        }

        try {
            $withdrawal = MerchantWithdrawalService::cancel($withdrawal);
        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        } catch (\Throwable $e) {
            Log::error('Withdrawal cancel error', [
                'error' => $e->getMessage(),
                'withdrawal_id' => $id,
                'user_id' => $user->id,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to cancel withdrawal request.',
            ], 500);
        }

        Log::info('Withdrawal cancelled', [
            'withdrawal_id' => $withdrawal->id,
            'user_id' => $user->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Withdrawal request cancelled successfully.',
            'data' => $withdrawal,
        ]);
    }

    /**
     * Get withdrawal summary (available balance, pending, etc.)
     */
    public function summary(Request $request)
    {
        try {
            $user = $request->user();
            $partner = $this->partnerFor($user);

            if (! $partner) {
                return $this->partnerMissing();
            }

            $wallet = Wallet::where('user_id', $partner->user_id)->first();

            if (! $wallet) {
                return response()->json([
                    'success' => false,
                    'message' => 'Wallet not found.',
                ], 404);
            }

            $totalBalance = (float) $wallet->balance;
            $pendingWithdrawals = $wallet->pendingWithdrawalAmount();
            $availableBalance = $wallet->availableBalance();

            $totalWithdrawn = (float) MerchantWithdrawalRequest::where('partner_id', $partner->id)
                ->where('status', MerchantWithdrawalRequest::STATUS_COMPLETED)
                ->sum('net_amount');

            $pendingCount = MerchantWithdrawalRequest::where('partner_id', $partner->id)
                ->where('status', MerchantWithdrawalRequest::STATUS_PENDING)
                ->count();

            return response()->json([
                'success' => true,
                'data' => [
                    'total_balance' => $totalBalance,
                    'available_balance' => $availableBalance,
                    'pending_withdrawals' => $pendingWithdrawals,
                    'total_withdrawn' => $totalWithdrawn,
                    'pending_count' => $pendingCount,
                    'currency' => $wallet->currency ?? 'PHP',
                    'min_withdrawal_amount' => 100.00,
                    'max_withdrawal_amount' => 999999.99,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Withdrawal summary error', [
                'error' => $e->getMessage(),
                'user_id' => $request->user()->id ?? null,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch withdrawal summary.',
            ], 500);
        }
    }
}
