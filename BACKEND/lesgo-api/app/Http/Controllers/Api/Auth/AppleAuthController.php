<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\AppleIdentityService;
use App\Services\AuditLogger;
use App\Services\AuthenticationService;
use App\Services\TwoFactorAuthService;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

class AppleAuthController extends Controller
{
    public function __construct(
        private AuthenticationService $authService,
        private TwoFactorAuthService $twoFactorService,
        private AppleIdentityService $appleIdentity,
    ) {}

    /**
     * Sign in / register with a Sign in with Apple identity token.
     *
     * POST /api/v1/auth/apple
     * Body: { "id_token": "...", "nonce": "...", "full_name": "...", "auth_mode": "login|signup" }
     */
    public function handleAppleSignIn(Request $request): JsonResponse
    {
        $request->validate([
            'id_token' => 'required|string',
            'nonce' => 'required|string|min:16|max:255',
            'full_name' => 'nullable|string|max:150',
            'device_name' => 'nullable|string|max:100',
            'auth_mode' => 'nullable|string|in:login,signup',
            'two_factor_code' => ['nullable', 'string', 'regex:/^(?:\d{6}|[A-Za-z0-9]{8})$/'],
        ]);

        $deviceName = $request->input('device_name', 'mobile-app');
        $authMode = $request->input('auth_mode', 'login');

        $claims = $this->appleIdentity->verifyIdToken(
            $request->input('id_token'),
            $request->input('nonce')
        );

        if (! $claims) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid Apple token. Please try again.',
            ], 401);
        }

        $appleId = (string) $claims['sub'];
        $email = isset($claims['email']) ? strtolower((string) $claims['email']) : null;
        $fullName = trim((string) $request->input('full_name', ''));

        try {
            $user = DB::transaction(function () use ($appleId, $email, $claims, $fullName, $authMode) {
                $columns = array_fill_keys(Schema::getColumnListing('users'), true);
                if (! isset($columns['apple_id'])) {
                    throw new \RuntimeException('The users table is missing the apple_id column.');
                }

                $row = DB::table('users')->where('apple_id', $appleId)->lockForUpdate()->first();

                if (! $row && $email !== null && ($claims['email_verified'] ?? false)) {
                    $row = DB::table('users')->where('email', $email)->lockForUpdate()->first();
                    if ($row && ! empty($row->apple_id)
                        && ! hash_equals((string) $row->apple_id, $appleId)) {
                        throw new AuthenticationException('This Apple identity does not match the linked account.');
                    }
                }

                if ($row) {
                    $updates = [];
                    if (empty($row->apple_id)) {
                        $updates['apple_id'] = $appleId;
                    }
                    if (isset($columns['deleted_at']) && $row->deleted_at !== null) {
                        $updates['deleted_at'] = null;
                    }
                    if ($updates) {
                        if (isset($columns['updated_at'])) {
                            $updates['updated_at'] = now();
                        }
                        DB::table('users')->where('id', $row->id)->update($updates);
                        foreach ($updates as $column => $value) {
                            $row->{$column} = $value;
                        }
                    }

                    return (new User())->newFromBuilder((array) $row);
                }

                // A login action must never create an account implicitly.
                if ($authMode === 'login') {
                    return null;
                }

                if ($email === null) {
                    throw new \InvalidArgumentException('Apple did not share an email address.');
                }

                $candidate = [
                    'name' => $fullName !== '' ? $fullName : 'Apple User',
                    'email' => $email,
                    'email_verified_at' => now(),
                    'password' => bcrypt(Str::random(32)),
                    'role' => 'customer',
                    'apple_id' => $appleId,
                    'referral_code' => strtoupper(Str::random(8)),
                    'points' => 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];

                $id = DB::table('users')->insertGetId(array_intersect_key($candidate, $columns));
                $created = (new User())->newFromBuilder((array) DB::table('users')->where('id', $id)->first());
                $created->wasRecentlyCreated = true;

                return $created;
            });
        } catch (AuthenticationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 401);
        } catch (\InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Apple did not share an email address. Please sign up with email instead.',
                'error_code' => 'APPLE_EMAIL_MISSING',
            ], 422);
        } catch (\Throwable $e) {
            \Log::error('Apple account creation failed', [
                'error' => $e->getMessage(),
                'exception' => $e::class,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Unable to create or load your Apple account. Please try again.',
                'error_code' => 'APPLE_ACCOUNT_CREATE_FAILED',
            ], 500);
        }

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'No account was found for this Apple ID. Please use Sign Up.',
                'error_code' => 'APPLE_ACCOUNT_NOT_FOUND',
            ], 404);
        }

        if ($user->is_active === false) {
            return response()->json([
                'success' => false,
                'message' => 'Your account has been deactivated. Please contact support.',
            ], 403);
        }

        if ($this->twoFactorService->has2FAEnabled($user)) {
            $code = trim((string) $request->input('two_factor_code', ''));

            if ($code === '') {
                return response()->json([
                    'success' => false,
                    'message' => 'Enter the code from Google Authenticator to continue.',
                    'two_factor_required' => true,
                    'two_factor_methods' => ['totp', 'backup_code'],
                ], 202);
            }

            $verified = preg_match('/^\d{6}$/', $code) === 1
                ? $this->twoFactorService->verifyTotp($user, $code)
                : $this->twoFactorService->verifyBackupCode($user, $code);

            if (! $verified) {
                return response()->json([
                    'success' => false,
                    'message' => 'The authenticator or backup code is invalid.',
                    'two_factor_required' => true,
                    'two_factor_methods' => ['totp', 'backup_code'],
                ], 422);
            }
        }

        try {
            AuditLogger::logAuth($user->wasRecentlyCreated ? 'apple_register' : 'apple_login', $user->id, true);
        } catch (\Throwable $e) {
            \Log::warning('Apple authentication audit log failed', ['error' => $e->getMessage()]);
        }

        $tokens = $this->authService->issueTokenPair($user, $deviceName);
        $requiresIdentityVerification = $authMode !== 'login'
            && $user->isCustomer()
            && ! $user->documentVerifications()
                ->where('document_type', 'valid_id')
                ->whereIn('status', ['pending', 'under_review', 'approved'])
                ->exists();

        return response()->json([
            'success' => true,
            'message' => 'Apple sign-in successful',
            'token' => $tokens['token'],
            'refresh_token' => $tokens['refresh_token'],
            'expires_in' => $tokens['expires_in'],
            'is_new_user' => (bool) $user->wasRecentlyCreated,
            'requires_identity_verification' => $requiresIdentityVerification,
            'user' => $user->only([
                'id', 'name', 'email', 'phone_number',
                'profile_photo_url', 'profile_picture',
                'referral_code', 'points', 'role',
                'email_verified_at', 'created_at',
            ]),
        ]);
    }
}
