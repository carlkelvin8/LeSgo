<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\AuthenticationService;
use App\Services\AuditLogger;
use App\Services\TwoFactorAuthService;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

class GoogleAuthController extends Controller
{
    public function __construct(
        private AuthenticationService $authService,
        private TwoFactorAuthService $twoFactorService,
    ) {}

    /**
     * Sign in / register with Google ID token.
     *
     * The Flutter app uses google_sign_in to get an idToken, then sends it here.
     * We verify it against Google's tokeninfo endpoint, then find-or-create the user.
     *
     * POST /api/v1/auth/google
     * Body: { "id_token": "...", "device_name": "mobile-app" }
     */
    public function handleGoogleSignIn(Request $request): JsonResponse
    {
        $request->validate([
            'id_token'    => 'required|string',
            'device_name' => 'nullable|string|max:100',
            'auth_mode' => 'nullable|string|in:login,signup',
            'two_factor_code' => ['nullable', 'string', 'regex:/^(?:\d{6}|[A-Za-z0-9]{8})$/'],
        ]);

        $idToken    = $request->input('id_token');
        $deviceName = $request->input('device_name', 'mobile-app');
        // "auto" preserves compatibility with app versions released before
        // login and signup were separated explicitly.
        $authMode = $request->input('auth_mode', 'auto');

        // ── Verify the ID token with Google ──────────────────────────────────
        $googleUser = app(\App\Services\GoogleIdentityVerifier::class)->verify($idToken);

        if (!$googleUser) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid Google token. Please try again.',
            ], 401);
        }

        // ── Find or create user ───────────────────────────────────────────────
        try {
            $user = DB::transaction(function () use ($googleUser, $authMode) {
                $columns = array_fill_keys(Schema::getColumnListing('users'), true);
                $existingQuery = DB::table('users')->where('email', $googleUser['email']);
                $existingRow = $existingQuery->lockForUpdate()->first();

                if ($existingRow) {
                    if (!empty($existingRow->google_id)
                        && !hash_equals((string) $existingRow->google_id, (string) $googleUser['sub'])) {
                        throw new \Illuminate\Auth\AuthenticationException('This Google identity does not match the linked account.');
                    }
                    // Update Google-specific fields if missing and available in this deployment.
                    $updates = [];
                    if (isset($columns['google_id']) && empty($existingRow->google_id) && isset($googleUser['sub'])) {
                        $updates['google_id'] = $googleUser['sub'];
                    }
                    if (isset($columns['profile_photo_url']) && empty($existingRow->profile_photo_url) && isset($googleUser['picture'])) {
                        $updates['profile_photo_url'] = $googleUser['picture'];
                    }
                    if (isset($columns['deleted_at']) && $existingRow->deleted_at !== null) {
                        $updates['deleted_at'] = null;
                    }
                    if ($updates) {
                        if (isset($columns['updated_at'])) {
                            $updates['updated_at'] = now();
                        }
                        DB::table('users')->where('id', $existingRow->id)->update($updates);
                        foreach ($updates as $column => $value) {
                            $existingRow->{$column} = $value;
                        }
                    }

                    return (new User())->newFromBuilder((array) $existingRow);
                }

                // A login action must never create an account implicitly. New
                // Google identities belong in the signup + ID verification flow.
                if ($authMode === 'login') {
                    return null;
                }

                // Use the actual deployed column list. This keeps Google signup working
                // while older preview databases are being brought up to the latest schema.
                $candidateAttributes = [
                    'name' => $googleUser['name'] ?? 'Google User',
                    'email' => $googleUser['email'],
                    'email_verified_at' => now(),
                    'password' => bcrypt(Str::random(32)),
                    'role' => 'customer',
                    'google_id' => $googleUser['sub'] ?? null,
                    'profile_photo_url' => $googleUser['picture'] ?? null,
                    'referral_code' => strtoupper(Str::random(8)),
                    'points' => 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];

                $attributes = array_intersect_key($candidateAttributes, $columns);
                if (!isset($attributes['name'], $attributes['email'])) {
                    throw new \RuntimeException('The users table is missing required Google signup columns.');
                }

                $userId = DB::table('users')->insertGetId($attributes);
                $createdRow = DB::table('users')->where('id', $userId)->first();
                if (!$createdRow) {
                    throw new \RuntimeException('The Google user was inserted but could not be reloaded.');
                }

                $created = (new User())->newFromBuilder((array) $createdRow);
                $created->wasRecentlyCreated = true;

                return $created;
            });
        } catch (\Illuminate\Auth\AuthenticationException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 401);
        } catch (\Throwable $e) {
            \Log::error('Google account creation failed', [
                'error' => $e->getMessage(),
                'exception' => $e::class,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Unable to create or load your Google account. Please try again.',
                'error_code' => 'GOOGLE_ACCOUNT_CREATE_FAILED',
                'failure_type' => $this->classifyAccountCreationFailure($e),
            ], 500);
        }

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'No account was found for this Google email. Please use Sign Up.',
                'error_code' => 'GOOGLE_ACCOUNT_NOT_FOUND',
            ], 404);
        }

        if ($user->wasRecentlyCreated) {
            $this->logAuthSafely('google_register', $user->id);
        }

        if ($user->is_active === false) {
            return response()->json([
                'success' => false,
                'message' => 'Your account has been deactivated. Please contact support.',
            ], 403);
        }

        if ($this->twoFactorService->has2FAEnabled($user)) {
            $twoFactorCode = trim((string) $request->input('two_factor_code', ''));

            if ($twoFactorCode === '') {
                return response()->json([
                    'success' => false,
                    'message' => 'Enter the code from Google Authenticator to continue.',
                    'two_factor_required' => true,
                    'two_factor_methods' => ['totp', 'backup_code'],
                ], 202);
            }

            $verified = preg_match('/^\d{6}$/', $twoFactorCode) === 1
                ? $this->twoFactorService->verifyTotp($user, $twoFactorCode)
                : $this->twoFactorService->verifyBackupCode($user, $twoFactorCode);

            if (!$verified) {
                return response()->json([
                    'success' => false,
                    'message' => 'The authenticator or backup code is invalid.',
                    'two_factor_required' => true,
                    'two_factor_methods' => ['totp', 'backup_code'],
                ], 422);
            }
        }

        $this->logAuthSafely('google_login', $user->id);

        $tokens = $this->authService->issueTokenPair($user, $deviceName);
        $requiresIdentityVerification = $authMode !== 'login'
            && $user->isCustomer()
            && !$user->documentVerifications()
                ->where('document_type', 'valid_id')
                ->whereIn('status', ['pending', 'under_review', 'approved'])
                ->exists();

        return response()->json([
            'success'    => true,
            'message'    => 'Google sign-in successful',
            'token'      => $tokens['token'],
            'refresh_token' => $tokens['refresh_token'],
            'expires_in' => $tokens['expires_in'],
            'is_new_user' => !$user->wasRecentlyCreated ? false : true,
            'requires_identity_verification' => $requiresIdentityVerification,
            'user'       => $this->formatUserResponse($user),
        ]);
    }

    private function formatUserResponse(User $user): array
    {
        return $user->only([
            'id', 'name', 'email', 'phone_number',
            'profile_photo_url', 'profile_picture',
            'referral_code', 'points', 'role',
            'email_verified_at', 'created_at',
        ]);
    }

    /**
     * Expose only a coarse database failure category so deployments can be
     * diagnosed without leaking SQL, account data, or provider tokens.
     */
    private function classifyAccountCreationFailure(\Throwable $exception): string
    {
        if (!$exception instanceof QueryException) {
            return 'application_error';
        }

        $sqlState = $exception->errorInfo[0] ?? (string) $exception->getCode();

        return match ($sqlState) {
            '23502' => 'required_field_missing',
            '23505' => 'account_conflict',
            '42703', '42S22' => 'user_schema_column_missing',
            '42P01', '42S02' => 'user_table_missing',
            default => 'database_error',
        };
    }

    /**
     * Authentication must not fail when audit storage is temporarily unavailable.
     */
    private function logAuthSafely(string $action, int $userId): void
    {
        try {
            AuditLogger::logAuth($action, $userId, true);
        } catch (\Throwable $e) {
            \Log::warning('Google authentication audit log failed', [
                'action' => $action,
                'user_id' => $userId,
                'error' => $e->getMessage(),
            ]);
        }
    }
}
