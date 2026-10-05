<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Wallet;
use App\Models\WalletLinkedAccount;
use App\Models\WalletTopUp;
use App\Models\WalletTransaction;
use App\Models\WalletWithdrawal;
use App\Services\CacheService;
use App\Services\LesPayTopUpFeeService;
use App\Services\PaymentGatewayManager;
use App\Services\PaymentGatewayService;
use App\Services\PayMongoService;
use App\Services\WalletService;
use App\Services\WalletValidationService;
use App\Services\WalletWithdrawalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

class WalletController extends Controller
{
    protected function authorizeWalletAccess(Request $request, int $userId): void
    {
        $auth = $request->user();

        if (! $auth) {
            abort(401, 'Unauthenticated');
        }

        if ((int) $auth->id !== (int) $userId && ! $auth->isAdmin()) {
            abort(403, 'Forbidden');
        }
    }

    /**
     * @OA\Get(
     *     path="/api/v1/wallets/{userId}",
     *     summary="Get wallet balance for a user",
     *     tags={"Wallets"},
     *     security={{"sanctum":{}}},
     *
     *     @OA\Parameter(name="userId", in="path", required=true, @OA\Schema(type="integer")),
     *
     *     @OA\Response(response=200, description="Wallet details",
     *
     *         @OA\JsonContent(@OA\Property(property="data", ref="#/components/schemas/Wallet"))
     *     ),
     *
     *     @OA\Response(response=403, ref="#/components/schemas/ErrorResponse")
     * )
     */
    public function showByUser(Request $request, int $userId): JsonResponse
    {
        $this->authorizeWalletAccess($request, $userId);

        $cacheKey = "wallets:user:{$userId}:balance";
        // Bust any stale cache so we always return fresh data.
        Cache::forget($cacheKey);

        $wallet = CacheService::remember($cacheKey, CacheService::CACHE_SHORT, function () use ($userId) {
            // Auto-create wallet on first access so the endpoint never 404/500.
            return WalletValidationService::ensureWalletExists(
                \App\Models\User::findOrFail($userId)
            );
        });

        return $this->success($wallet);
    }

    /**
     * @OA\Get(
     *     path="/api/v1/wallets/{userId}/transactions",
     *     summary="Get wallet transactions for a user",
     *     tags={"Wallets"},
     *     security={{"sanctum":{}}},
     *
     *     @OA\Parameter(name="userId", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\Parameter(name="type", in="query", required=false, @OA\Schema(type="string", enum={"credit","debit"})),
     *
     *     @OA\Response(response=200, description="List of transactions",
     *
     *         @OA\JsonContent(
     *
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="array", @OA\Items(ref="#/components/schemas/WalletTransaction"))
     *         )
     *     ),
     *
     *     @OA\Response(response=403, ref="#/components/schemas/ErrorResponse"),
     *     @OA\Response(response=422, ref="#/components/schemas/ErrorResponse")
     * )
     */
    public function transactionsByUser(Request $request, int $userId): JsonResponse
    {
        $this->authorizeWalletAccess($request, $userId);

        $type = $request->query('type');

        if ($type && ! in_array($type, ['credit', 'debit'], true)) {
            return $this->error('Invalid type. Allowed: credit, debit', 422);
        }

        try {
            return $this->success($this->fetchWalletTransactions($userId, $type));
        } catch (\Throwable $e) {
            Log::error('Wallet transactions fetch failed', [
                'user_id' => $userId,
                'error' => $e->getMessage(),
            ]);

            // Empty list keeps the mobile history screen usable.
            return $this->success([]);
        }
    }

    public function myWallet(Request $request): JsonResponse
    {
        return $this->showByUser($request, (int) $request->user()->id);
    }

    public function myTransactions(Request $request): JsonResponse
    {
        return $this->transactionsByUser($request, (int) $request->user()->id);
    }

    /**
     * @OA\Get(
     *     path="/api/v1/wallets/my/validation",
     *     summary="Check wallet balance validation for current user",
     *     tags={"Wallets"},
     *     security={{"sanctum":{}}},
     *
     *     @OA\Response(response=200, description="Wallet validation details",
     *
     *         @OA\JsonContent(
     *
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="has_sufficient_balance", type="boolean"),
     *                 @OA\Property(property="current_balance", type="number", format="float"),
     *                 @OA\Property(property="minimum_threshold", type="number", format="float"),
     *                 @OA\Property(property="shortfall", type="number", format="float")
     *             )
     *         )
     *     )
     * )
     */
    public function myPayouts(Request $request): JsonResponse
    {
        $user = $request->user();

        try {
            $payouts = WalletWithdrawal::query()
                ->where('user_id', $user->id)
                ->orderByDesc('created_at')
                ->limit(100)
                ->get()
                ->map(fn (WalletWithdrawal $withdrawal) => [
                    'id' => $withdrawal->id,
                    'amount' => (float) $withdrawal->amount,
                    'status' => $withdrawal->status,
                    'payment_method' => $withdrawal->withdrawal_method,
                    'account_number' => $withdrawal->account_last4
                        ? '••••'.$withdrawal->account_last4
                        : '',
                    'requested_at' => $withdrawal->created_at?->toIso8601String(),
                    'completed_at' => $withdrawal->completed_at?->toIso8601String(),
                ])
                ->values()
                ->all();

            return $this->success($payouts);
        } catch (\Throwable $e) {
            return $this->success([]);
        }
    }

    public function myWalletValidation(Request $request): JsonResponse
    {
        $user = $request->user();
        $validation = WalletValidationService::validateBalance($user);

        return $this->success($validation);
    }

    /**
     * @OA\Get(
     *     path="/api/v1/wallets/threshold",
     *     summary="Get minimum wallet balance threshold",
     *     tags={"Wallets"},
     *     security={{"sanctum":{}}},
     *
     *     @OA\Response(response=200, description="Minimum threshold",
     *
     *         @OA\JsonContent(
     *
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="minimum_threshold", type="number", format="float")
     *             )
     *         )
     *     )
     * )
     */
    public function getThreshold(Request $request): JsonResponse
    {
        $threshold = WalletValidationService::getMinimumThreshold();

        return $this->success([
            'minimum_threshold' => $threshold,
        ]);
    }

    /**
     * Create a top-up invoice via PayMongo/Xendit or confirm a completed top-up.
     */
    public function topUp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount' => 'required_without:gateway_reference|numeric|min:10|max:100000',
            'payment_method' => 'nullable|string|in:paymongo,xendit,gcash,maya,card',
            'gateway_reference' => 'nullable|string',
            'xendit_invoice_id' => 'nullable|string',
            'external_reference' => 'nullable|string',
            'provider' => 'nullable|string|in:paymongo,xendit',
            'idempotency_key' => 'nullable|string|max:64',
        ]);

        $user = $request->user();
        $gatewayRef = $validated['gateway_reference'] ?? $validated['xendit_invoice_id'] ?? null;

        if (! empty($gatewayRef)) {
            return $this->confirmTopUp($request, $gatewayRef);
        }

        // Idempotency: prevent duplicate invoice creation from double-taps
        $idempotencyKey = $validated['idempotency_key'] ?? null;
        if ($idempotencyKey) {
            $cacheKey = "topup:idempotency:{$user->id}:{$idempotencyKey}";
            $cached = Cache::get($cacheKey);
            if ($cached) {
                return $this->created($cached, 'Top-up invoice already created (duplicate request)');
            }
        }

        // Anomaly detection: check for wallet abuse patterns
        $anomalyService = app(\App\Services\AnomalyDetectionService::class);
        $walletAmount = (float) $validated['amount'];
        $anomalyResult = $anomalyService->checkWalletAnomaly($user->id, $walletAmount, 'credit');
        if ($anomalyResult['is_suspicious']) {
            Log::warning('Top-up blocked by anomaly detection', [
                'user_id' => $user->id,
                'amount' => $walletAmount,
                'anomalies' => $anomalyResult['anomalies'],
            ]);
            // Only block if critical severity (money laundering pattern)
            $hasCritical = collect($anomalyResult['anomalies'])->contains('severity', 'critical');
            if ($hasCritical) {
                return $this->error('Transaction flagged for security review. Please try again later or contact support.', 403);
            }
        }

        $gateway = app(PaymentGatewayManager::class);
        $provider = $validated['provider'] ?? null;

        if (! PayMongoService::configured() && PaymentGatewayService::secretKey() === '') {
            return $this->error('No payment gateway is configured on the server.', 503);
        }

        $wallet = WalletValidationService::ensureWalletExists($user);
        $externalId = $validated['external_reference'] ?? ('lespay-topup-'.$user->id.'-'.Str::uuid());
        $method = $validated['payment_method'] ?? 'paymongo';
        $pricing = LesPayTopUpFeeService::calculate($walletAmount);

        $description = sprintf(
            'LeSgo LesPay Top-up ₱%s + %s%% fee (₱%s)',
            number_format($pricing['wallet_amount'], 2),
            (int) ($pricing['fee_rate'] * 100),
            number_format($pricing['fee'], 2),
        );

        $statementDescriptor = 'LeSgo Courier Service';

        try {
            $invoice = $gateway->createInvoice(
                $pricing['total_charged'],
                $externalId,
                $description,
                [
                    'success_redirect_url' => 'lesgo://lespay/topup/success',
                    'failure_redirect_url' => 'lesgo://lespay/topup/failure',
                    'customer_email' => $user->email,
                    'customer_name' => $user->name,
                    'payer_email' => $user->email,
                    'payer_name' => $user->name,
                    'payer_phone' => $user->phone_number,
                    'payment_method' => $method,
                    'statement_descriptor' => $statementDescriptor,
                ],
                $provider,
            );

            $resolvedProvider = $invoice['provider'] ?? $gateway->resolveProvider($provider);

            try {
                WalletTopUp::updateOrCreate(
                    ['external_id' => $externalId],
                    [
                        'user_id' => $user->id,
                        'wallet_id' => $wallet->id,
                        'amount' => $pricing['wallet_amount'],
                        'fee' => $pricing['fee'],
                        'total_charged' => $pricing['total_charged'],
                        'currency' => 'PHP',
                        'status' => 'pending',
                        'payment_method' => $method,
                        'provider' => $resolvedProvider,
                        'xendit_invoice_id' => $resolvedProvider === 'xendit' ? $invoice['id'] : null,
                        'gateway_reference' => $invoice['id'],
                        'invoice_url' => $invoice['invoice_url'],
                        'meta' => ['fee_rate' => $pricing['fee_rate']],
                    ]
                );
            } catch (\Throwable $dbErr) {
                Log::warning('WalletTopUp persist failed after invoice created', [
                    'external_id' => $externalId,
                    'invoice_id' => $invoice['id'],
                    'provider' => $resolvedProvider,
                    'error' => $dbErr->getMessage(),
                ]);

                throw new \RuntimeException(
                    'The payment invoice could not be recorded. Please do not pay it and try again.',
                    previous: $dbErr,
                );
            }

            CacheService::forgetByPattern("wallets:user:{$user->id}:*");

            $responseData = [
                'invoice_id' => $invoice['id'],
                'invoice_url' => $invoice['invoice_url'],
                'amount' => $pricing['wallet_amount'],
                'fee' => $pricing['fee'],
                'total_charged' => $pricing['total_charged'],
                'fee_rate' => $pricing['fee_rate'],
                'provider' => $resolvedProvider,
                'status' => strtolower($invoice['status'] ?? 'pending'),
            ];

            // Cache idempotency response for 10 minutes
            if ($idempotencyKey) {
                Cache::put($cacheKey, $responseData, now()->addMinutes(10));
            }

            return $this->created($responseData, 'Top-up invoice created');
        } catch (\Throwable $e) {
            return $this->error($e->getMessage(), 502);
        }
    }

    public function withdraw(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount' => 'required|numeric|min:10|max:100000',
            'withdrawal_method' => 'required|string|in:gcash,maya,paymaya',
        ]);

        if (! PayMongoService::configured() && PaymentGatewayService::secretKey() === '') {
            return $this->error('No payment gateway is configured on the server.', 503);
        }

        $user = $request->user();

        // Registration fee activation check — rider cannot withdraw earnings while restricted
        if ($user->isDriver() || $user->isPartnerAdmin()) {
            try {
                \App\Services\RegistrationFeeService::assertCanAccessOperationalFeatures($user, 'withdrawals');
            } catch (\RuntimeException $e) {
                return $this->error($e->getMessage(), 403);
            }
        }

        $amount = (float) $validated['amount'];

        // Anomaly detection: check for money laundering patterns
        $anomalyService = app(\App\Services\AnomalyDetectionService::class);
        $anomalyResult = $anomalyService->checkWalletAnomaly($user->id, $amount, 'debit');
        if ($anomalyResult['is_suspicious']) {
            $hasCritical = collect($anomalyResult['anomalies'])->contains('severity', 'critical');
            if ($hasCritical) {
                Log::warning('Withdrawal blocked by anomaly detection', [
                    'user_id' => $user->id,
                    'amount' => $amount,
                    'anomalies' => $anomalyResult['anomalies'],
                ]);

                return $this->error('Withdrawal flagged for security review. Please try again later or contact support.', 403);
            }
        }

        try {
            $result = WalletWithdrawalService::process(
                $user,
                $amount,
                $validated['withdrawal_method'],
            );

            $payout = $result['payout'];
            $provider = $payout['provider'] ?? 'paymongo';

            return $this->success([
                'wallet' => $result['wallet'],
                'payout' => $payout,
                'provider' => $provider,
            ], 'Withdrawal sent to your account via '.ucfirst($provider));
        } catch (\Throwable $e) {
            return $this->error($e->getMessage(), 422);
        }
    }

    private function confirmTopUp(Request $request, string $invoiceId): JsonResponse
    {
        $user = $request->user();

        $topUp = WalletTopUp::where('user_id', $user->id)
            ->where(function ($q) use ($invoiceId) {
                $q->where('gateway_reference', $invoiceId)
                    ->orWhere('xendit_invoice_id', $invoiceId);
            })->first();

        if (! $topUp) {
            return $this->error('Top-up record not found.', 404);
        }

        $wallet = WalletValidationService::ensureWalletExists($user);
        if ($topUp->isPaid()) {
            return $this->success($wallet->fresh(), 'Top-up already completed');
        }

        $provider = strtolower((string) $topUp->provider);
        $gateway = app(PaymentGatewayManager::class);

        try {
            $invoice = $gateway->getInvoice($invoiceId, $provider);
        } catch (\Throwable $verificationError) {
            Log::warning('Wallet top-up verification failed', [
                'invoice_id' => $invoiceId,
                'provider' => $provider,
                'top_up_id' => $topUp->id,
                'error' => $verificationError->getMessage(),
            ]);

            return $this->error('Payment verification failed. Please try again.', 502);
        }

        $status = $gateway->normalizeInvoiceStatus($invoice, $provider);
        if ($status !== 'paid') {
            if (in_array($status, ['failed', 'refunded'], true)) {
                $topUp->update(['status' => 'failed']);
            }

            return $this->error('Payment is not completed yet.', 402);
        }

        try {
            WalletService::completeTopUp($topUp);

            return $this->success(
                WalletValidationService::ensureWalletExists($user)->fresh(),
                'Top-up completed'
            );
        } catch (\Throwable $e) {
            Log::error('confirmTopUp failed', ['invoice_id' => $invoiceId, 'error' => $e->getMessage()]);

            return $this->error($e->getMessage(), 502);
        }
    }

    public function linkedAccounts(Request $request): JsonResponse
    {
        $user = $request->user();
        $accounts = WalletLinkedAccount::where('user_id', $user->id)
            ->orderBy('provider')
            ->get();

        return $this->success($accounts, 'Linked accounts retrieved');
    }

    public function linkAccount(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'provider' => 'required|string|in:maya,gcash,bank',
            'account_label' => 'nullable|string|max:120',
            'account_last4' => 'nullable|string|max:4',
            'account_number' => 'nullable|string|max:32',
            'account_holder_name' => 'nullable|string|max:120',
        ]);

        $user = $request->user();
        $provider = $validated['provider'];

        $meta = ['linked_at' => now()->toISOString()];
        $accountNumber = null;
        $accountDetails = null;

        if (! empty($validated['account_number'])) {
            $accountNumber = WalletWithdrawalService::normalizeAccountNumber(
                $validated['account_number']
            );
            $accountDetails = [
                'account_number' => $accountNumber,
                'account_holder_name' => trim(
                    $validated['account_holder_name'] ?? $user->name
                ),
            ];
        }

        $account = WalletLinkedAccount::firstOrNew([
            'user_id' => $user->id,
            'provider' => $provider,
        ]);
        $account->fill([
            'account_label' => $validated['account_label']
                ?? match ($provider) {
                    'maya' => 'PayMaya',
                    'gcash' => 'GCash',
                    default => 'Bank Account',
                },
            'account_last4' => $validated['account_last4']
                ?? ($accountNumber ? substr($accountNumber, -4) : $account->account_last4),
            // Presence of a number proves only that the user typed a value;
            // it does not prove they control the payout destination.
            'is_verified' => false,
            'meta' => array_merge($account->meta ?? [], $meta),
        ]);
        if ($accountDetails !== null) {
            $account->account_details_encrypted = $accountDetails;
        }
        $account->save();

        $message = $provider === 'bank'
            ? 'Bank account saved. Withdrawals to bank coming soon.'
            : ($accountNumber
                ? 'Account linked for withdrawals.'
                : 'Account linked. Add mobile number to enable withdrawals.');

        return $this->created($account, $message);
    }

    public function unlinkAccount(Request $request, string $provider): JsonResponse
    {
        $deleted = WalletLinkedAccount::where('user_id', $request->user()->id)
            ->where('provider', $provider)
            ->delete();

        if (! $deleted) {
            return $this->error('Linked account not found', 404);
        }

        return $this->message('Linked account removed');
    }

    public function verifyLinkedAccount(Request $request, string $provider): JsonResponse
    {
        $account = WalletLinkedAccount::where('user_id', $request->user()->id)
            ->where('provider', $provider)
            ->first();

        if (! $account) {
            return $this->error('Linked account not found', 404);
        }

        return $this->error(
            'Payout account ownership has not been verified by the payment provider.',
            409
        );
    }

    /**
     * Ledger rows for wallet history — tolerant of partial/missing columns on older DBs.
     *
     * @return list<array<string, mixed>>
     */
    private function fetchWalletTransactions(int $userId, ?string $type): array
    {
        if (! Schema::hasTable('wallet_transactions')) {
            return [];
        }

        $wallet = WalletValidationService::ensureWalletExists(
            \App\Models\User::findOrFail($userId)
        );

        $columns = Schema::getColumnListing('wallet_transactions');
        if (! in_array('wallet_id', $columns, true)) {
            return [];
        }

        $query = DB::table('wallet_transactions')->where('wallet_id', $wallet->id);

        if ($type && in_array('type', $columns, true)) {
            $query->where('type', $type);
        }

        if (in_array('id', $columns, true)) {
            $query->orderByDesc('id');
        } elseif (in_array('created_at', $columns, true)) {
            $query->orderByDesc('created_at');
        }

        return $query->limit(200)->get()->map(function ($row) {
            $data = (array) $row;

            return [
                'id' => $data['id'] ?? null,
                'wallet_id' => $data['wallet_id'] ?? null,
                'type' => $data['type'] ?? 'transaction',
                'amount' => isset($data['amount']) ? (float) $data['amount'] : 0.0,
                'description' => $data['description']
                    ?? $data['reference']
                    ?? null,
                'created_at' => isset($data['created_at'])
                    ? (string) $data['created_at']
                    : null,
            ];
        })->values()->all();
    }
}
