<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

/**
 * Rate Limit Service Provider
 *
 * Configures tiered rate limiting:
 * - Public endpoints: moderate limits to prevent abuse
 * - Auth endpoints: strict to prevent brute force
 * - Authenticated endpoints: generous for normal usage
 * - Sensitive endpoints: very strict (OTP, payments, password reset)
 *
 * All limits are per-IP for unauthenticated, per-user for authenticated.
 * Limits are relaxed in local/testing environment to avoid blocking developers.
 */
class RateLimitServiceProvider extends ServiceProvider
{
    public function register(): void {}

    public function boot(): void
    {
        $this->configureRateLimiting();
    }

    protected function configureRateLimiting(): void
    {
        $isLocal = app()->environment('local', 'testing');

        // =====================================================================
        // GLOBAL API (public unauthenticated endpoints)
        // Normal: 100/min per IP | Local: 600/min
        // =====================================================================
        RateLimiter::for('api', function (Request $request) use ($isLocal) {
            $limit = $isLocal ? 600 : 100;

            return Limit::perMinute($limit)
                ->by($request->user()?->id ?: $request->ip())
                ->response(function (Request $request, array $headers) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Too many requests. Please slow down.',
                        'retry_after' => $headers['Retry-After'] ?? 60,
                    ], 429, $headers);
                });
        });

        // =====================================================================
        // AUTHENTICATION (login, register, google sign-in)
        // Normal: 10/min per IP | Local: 120/min
        // Generous enough for real users but blocks brute force
        // =====================================================================
        RateLimiter::for('auth', function (Request $request) use ($isLocal) {
            $limit = $isLocal ? 120 : 10;

            return Limit::perMinute($limit)
                ->by($request->ip())
                ->response(function (Request $request, array $headers) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Too many login attempts. Please try again in a few minutes.',
                        'retry_after' => $headers['Retry-After'] ?? 60,
                    ], 429, $headers);
                });
        });

        // =====================================================================
        // OTP / VERIFICATION (very strict — prevents SMS bombing)
        // Normal: 3/min per phone or IP | Local: 30/min
        // =====================================================================
        RateLimiter::for('otp', function (Request $request) use ($isLocal) {
            $limit = $isLocal ? 30 : 3;
            $key = $request->input('phone_number') ?: $request->input('phone') ?: $request->ip();

            return Limit::perMinute($limit)
                ->by($key)
                ->response(function (Request $request, array $headers) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Too many OTP requests. Please wait before trying again.',
                        'retry_after' => $headers['Retry-After'] ?? 60,
                    ], 429, $headers);
                });
        });

        RateLimiter::for('password-reset', function (Request $request) use ($isLocal) {
            $limit = $isLocal ? 30 : 5;
            $email = strtolower(trim((string) $request->input('email')));
            $key = hash('sha256', $email.'|'.$request->ip());

            return Limit::perMinute($limit)
                ->by($key)
                ->response(function (Request $request, array $headers) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Too many password reset attempts. Please wait before trying again.',
                        'retry_after' => $headers['Retry-After'] ?? 60,
                    ], 429, $headers);
                });
        });

        // =====================================================================
        // AUTHENTICATED (all protected endpoints for logged-in users)
        // Normal: 120/min per user | Local: 600/min
        // Very generous — normal app usage should never hit this
        // =====================================================================
        RateLimiter::for('authenticated', function (Request $request) use ($isLocal) {
            $limit = $isLocal ? 600 : 120;

            return Limit::perMinute($limit)
                ->by($request->user()?->id ?: $request->ip())
                ->response(function (Request $request, array $headers) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Too many requests. Please slow down.',
                        'retry_after' => $headers['Retry-After'] ?? 60,
                    ], 429, $headers);
                });
        });

        // =====================================================================
        // ORDERS (creation/updates — prevent duplicate order spam)
        // Normal: 15/min per user | Local: 120/min
        // =====================================================================
        RateLimiter::for('orders', function (Request $request) use ($isLocal) {
            $limit = $isLocal ? 120 : 15;

            return Limit::perMinute($limit)
                ->by($request->user()?->id ?: $request->ip())
                ->response(function (Request $request, array $headers) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Too many order requests. Please slow down.',
                        'retry_after' => $headers['Retry-After'] ?? 60,
                    ], 429, $headers);
                });
        });

        // =====================================================================
        // PAYMENTS (strict — prevent payment abuse)
        // Normal: 5/min per user | Local: 60/min
        // =====================================================================
        RateLimiter::for('payments', function (Request $request) use ($isLocal) {
            $limit = $isLocal ? 60 : 5;

            return Limit::perMinute($limit)
                ->by($request->user()?->id ?: $request->ip())
                ->response(function (Request $request, array $headers) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Too many payment requests. Please wait.',
                        'retry_after' => $headers['Retry-After'] ?? 60,
                    ], 429, $headers);
                });
        });

        // =====================================================================
        // BROWSE (search, list partners, etc — lenient)
        // Normal: 60/min per IP | Local: 300/min
        // =====================================================================
        RateLimiter::for('browse', function (Request $request) use ($isLocal) {
            $limit = $isLocal ? 300 : 60;

            return Limit::perMinute($limit)
                ->by($request->user()?->id ?: $request->ip());
        });

        // =====================================================================
        // UPLOADS (file uploads — moderate)
        // Normal: 10/min per user | Local: 60/min
        // =====================================================================
        RateLimiter::for('uploads', function (Request $request) use ($isLocal) {
            $limit = $isLocal ? 60 : 10;

            return Limit::perMinute($limit)
                ->by($request->user()?->id ?: $request->ip())
                ->response(function (Request $request, array $headers) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Too many upload requests. Please wait.',
                        'retry_after' => $headers['Retry-After'] ?? 60,
                    ], 429, $headers);
                });
        });

        // =====================================================================
        // DRIVER REGISTRATION (strict — prevent spam registrations)
        // Normal: 3/min per IP | Local: 30/min
        // =====================================================================
        RateLimiter::for('driver-registration', function (Request $request) use ($isLocal) {
            $limit = $isLocal ? 30 : 3;

            return Limit::perMinute($limit)
                ->by($request->ip())
                ->response(function (Request $request, array $headers) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Too many registration attempts. Please try again later.',
                        'retry_after' => $headers['Retry-After'] ?? 60,
                    ], 429, $headers);
                });
        });

        // =====================================================================
        // SENSITIVE (password change, account deletion, 2FA)
        // Normal: 3/min per user | Local: 30/min
        // =====================================================================
        RateLimiter::for('sensitive', function (Request $request) use ($isLocal) {
            $limit = $isLocal ? 30 : 3;

            return Limit::perMinute($limit)
                ->by($request->user()?->id ?: $request->ip())
                ->response(function (Request $request, array $headers) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Too many attempts on this sensitive action. Please wait.',
                        'retry_after' => $headers['Retry-After'] ?? 60,
                    ], 429, $headers);
                });
        });

        // =====================================================================
        // ADMIN (lenient for authenticated admins)
        // Normal: 200/min | Local: 1000/min
        // =====================================================================
        RateLimiter::for('admin', function (Request $request) use ($isLocal) {
            $limit = $isLocal ? 1000 : 200;

            return Limit::perMinute($limit)
                ->by($request->user()?->id ?: $request->ip());
        });

        // =====================================================================
        // WEBHOOKS (very lenient — external services call these)
        // Normal: 1000/min per IP | These are from Xendit/PayMongo servers
        // =====================================================================
        RateLimiter::for('webhooks', function (Request $request) {
            return Limit::perMinute(1000)
                ->by($request->ip());
        });

        // =====================================================================
        // PUBLIC CONFIG (health, config, version check)
        // Normal: 30/min per IP — prevents scraping
        // =====================================================================
        RateLimiter::for('public-config', function (Request $request) use ($isLocal) {
            $limit = $isLocal ? 300 : 30;

            return Limit::perMinute($limit)
                ->by($request->ip());
        });
    }
}
