<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Validates request origin for state-changing (POST/PUT/DELETE) endpoints.
 *
 * This is the API equivalent of CSRF protection for token-based auth:
 * - Mobile apps: Always allowed (no Origin/Referer header or custom User-Agent)
 * - Web browsers: Must come from allowed origins (prevents malicious sites from
 *   making requests on behalf of logged-in users who happen to have a valid token)
 * - Webhooks: Excluded (verified by their own token mechanisms)
 *
 * This middleware does NOT block:
 * - GET/HEAD/OPTIONS requests (read-only, safe)
 * - Requests without Origin header (mobile apps, Postman, curl)
 * - Requests from allowed origins
 *
 * It only blocks:
 * - POST/PUT/DELETE from web browsers with an Origin header that doesn't match
 *   our allowed list (i.e., a malicious website trying to use a stolen token)
 */
class ValidateRequestOrigin
{
    /**
     * HTTP methods that modify state and should be validated.
     */
    private const STATE_CHANGING_METHODS = ['POST', 'PUT', 'PATCH', 'DELETE'];

    /**
     * Route prefixes to exclude from origin validation.
     * (Webhooks have their own authentication mechanisms)
     */
    private const EXCLUDED_PREFIXES = [
        'api/v1/webhooks',
        'api/v1/broadcasting',
    ];

    public function handle(Request $request, Closure $next): Response
    {
        // Only validate state-changing requests
        if (! in_array($request->method(), self::STATE_CHANGING_METHODS)) {
            return $next($request);
        }

        // Skip excluded routes (webhooks, etc.)
        $path = $request->path();
        foreach (self::EXCLUDED_PREFIXES as $prefix) {
            if (str_starts_with($path, $prefix)) {
                return $next($request);
            }
        }

        // Get the Origin header (sent by browsers on cross-origin requests)
        $origin = $request->header('Origin');

        // No Origin header = not a browser cross-origin request
        // Mobile apps (Flutter/Dio) don't send Origin headers
        // This is safe to allow through
        if (empty($origin)) {
            return $next($request);
        }

        // Validate against allowed origins
        $allowedOrigins = $this->getAllowedOrigins();

        // Wildcard means all origins allowed (development mode)
        if (in_array('*', $allowedOrigins)) {
            return $next($request);
        }

        // Check if origin is in allowed list
        $originHost = strtolower((string) parse_url($origin, PHP_URL_HOST));
        foreach ($allowedOrigins as $allowed) {
            if ($origin === $allowed) {
                return $next($request);
            }
            // Support wildcard subdomains: *.lesgo.ph
            if (str_starts_with($allowed, '*.')) {
                $domain = strtolower(substr($allowed, 2));
                if ($originHost !== '' && str_ends_with($originHost, '.'.$domain)) {
                    return $next($request);
                }
            }
        }

        // Origin not allowed — this is likely a cross-origin attack
        return response()->json([
            'success' => false,
            'message' => 'Request origin not allowed.',
        ], 403);
    }

    /**
     * Get allowed origins from CORS config.
     * Uses config() which is safe with config:cache (unlike env()).
     */
    private function getAllowedOrigins(): array
    {
        $origins = config('cors.allowed_origins', ['*']);

        // If wildcard is present, allow everything
        if (in_array('*', $origins)) {
            return ['*'];
        }

        return array_unique(array_filter($origins));
    }
}
