<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Mail\PasswordResetOtpMail;
use App\Models\User;
use App\Services\PasswordResetService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\Rules\Password;

class ForgotPasswordController extends Controller
{
    public function __construct(private PasswordResetService $passwordResetService) {}

    public function sendOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email:rfc', 'max:255'],
        ]);
        $email = strtolower(trim($validated['email']));
        $user = User::where('email', $email)->first();

        // Keep account existence private from callers.
        if (! $user) {
            return $this->otpSentResponse();
        }

        $issued = $this->passwordResetService->issue($email, $request->ip());

        try {
            Mail::to($email)->send(new PasswordResetOtpMail(
                otp: $issued['otp'],
                userName: $user->name,
                expiryMinutes: 10,
            ));
        } catch (\Throwable $e) {
            $this->passwordResetService->invalidate($issued['challenge']);
            Log::error('Failed to send password reset OTP.', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Unable to send a password reset code right now. Please try again later.',
            ], 503);
        }

        return $this->otpSentResponse();
    }

    public function verifyOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email:rfc', 'max:255'],
            'otp' => ['required', 'string', 'regex:/^\d{6}$/'],
        ]);

        $resetToken = $this->passwordResetService->verify(
            strtolower(trim($validated['email'])),
            $validated['otp'],
        );

        if (! $resetToken) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired verification code.',
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Verification code accepted.',
            'reset_token' => $resetToken,
            'expires_in_minutes' => 15,
        ]);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email:rfc', 'max:255'],
            'reset_token' => ['required', 'string', 'size:64'],
            'password' => [
                'required',
                'confirmed',
                Password::min(8)->mixedCase()->numbers(),
            ],
        ]);

        $reset = $this->passwordResetService->resetPassword(
            strtolower(trim($validated['email'])),
            $validated['reset_token'],
            $validated['password'],
        );

        if (! $reset) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired password reset request.',
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Password reset successfully. Please log in with your new password.',
        ]);
    }

    public function resendOtp(Request $request): JsonResponse
    {
        return $this->sendOtp($request);
    }

    private function otpSentResponse(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'If this email is registered, a verification code will be sent.',
            'expires_in_minutes' => 10,
        ]);
    }
}
