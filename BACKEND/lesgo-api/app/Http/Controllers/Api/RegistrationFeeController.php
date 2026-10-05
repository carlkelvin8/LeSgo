<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\RegistrationFeeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RegistrationFeeController extends Controller
{
    /**
     * Get current user's registration fee & application status.
     */
    public function status(Request $request): JsonResponse
    {
        $user = $request->user();

        $status = RegistrationFeeService::getStatusForUser($user);

        return $this->success($status, 'Registration status retrieved');
    }

    /**
     * Create PayMongo checkout for registration fee.
     */
    public function createCheckout(Request $request): JsonResponse
    {
        $user = $request->user();

        $accountType = RegistrationFeeService::accountTypeForUser($user);
        if (!$accountType) {
            return $this->error('Only Rider and Merchant accounts require registration fee', 422);
        }

        try {
            $result = RegistrationFeeService::createCheckout($user, $accountType);

            return $this->success([
                'checkout_url' => $result['checkout_url'],
                'checkout_id' => $result['checkout_id'] ?? null,
                'paymongo_reference' => $result['paymongo_reference'],
                'amount' => (float) $result['payment']->amount,
                'currency' => $result['payment']->currency,
                'payment_status' => $result['payment']->payment_status,
                'status_message' => $result['payment']->displayCombinedStatus(),
                'reused' => $result['reused'] ?? false,
            ], $result['reused'] ? 'Checkout already exists (reused)' : 'Checkout created');
        } catch (\RuntimeException $e) {
            return $this->error($e->getMessage(), 422);
        } catch (\Throwable $e) {
            \Log::error('Registration fee checkout failed', ['user_id' => $user->id, 'error' => $e->getMessage()]);
            return $this->error('Failed to create checkout: ' . $e->getMessage(), 502);
        }
    }

    /**
     * Verify payment after redirect from PayMongo.
     */
    public function verify(Request $request): JsonResponse
    {
        $user = $request->user();
        $accountType = RegistrationFeeService::accountTypeForUser($user);
        if (!$accountType) {
            return $this->error('Only Rider and Merchant accounts require registration fee', 422);
        }

        $validated = $request->validate([
            'checkout_id' => 'nullable|string',
            'paymongo_checkout_id' => 'nullable|string',
        ]);

        $checkoutId = $validated['checkout_id'] ?? $validated['paymongo_checkout_id'] ?? null;

        try {
            $payment = RegistrationFeeService::verifyPayment($user, $checkoutId);
            $status = RegistrationFeeService::getStatusForUser($user);

            return $this->success([
                'payment' => $payment,
                'status' => $status,
            ], 'Payment verification completed');
        } catch (\RuntimeException $e) {
            return $this->error($e->getMessage(), 422);
        } catch (\Throwable $e) {
            return $this->error('Verification failed: ' . $e->getMessage(), 502);
        }
    }

    /**
     * Config endpoint: public fee amounts
     */
    public function config(): JsonResponse
    {
        return $this->success([
            'rider_fee' => RegistrationFeeService::getFeeForType('rider'),
            'merchant_fee' => RegistrationFeeService::getFeeForType('merchant'),
            'merchant_billing_period' => 'annual',
            'currency' => 'PHP',
        ], 'Registration fee config');
    }
}
