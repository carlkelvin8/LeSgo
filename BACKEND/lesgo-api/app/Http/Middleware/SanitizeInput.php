<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class SanitizeInput
{
    /**
     * Sanitize user input to prevent XSS and injection attacks.
     */
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->isJson()) {
            $maxBytes = max(1, (int) config('app.max_json_body_bytes', 2 * 1024 * 1024));
            $declaredLength = $request->server('CONTENT_LENGTH');

            if (is_numeric($declaredLength) && (int) $declaredLength > $maxBytes) {
                return $this->payloadTooLargeResponse();
            }

            $content = $request->getContent();
            if (strlen($content) > $maxBytes) {
                return $this->payloadTooLargeResponse();
            }

            if (trim($content) !== '') {
                json_decode($content, true);
                if (json_last_error() !== JSON_ERROR_NONE) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Malformed JSON request body.',
                    ], 400);
                }
            }
        }

        $input = $request->all();

        array_walk_recursive($input, function (&$value) {
            if (is_string($value)) {
                // Remove null bytes
                $value = str_replace("\0", '', $value);

                // Trim whitespace
                $value = trim($value);

                // Remove control characters except newlines and tabs
                $value = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/u', '', $value);
            }
        });

        $request->merge($input);

        return $next($request);
    }

    private function payloadTooLargeResponse(): Response
    {
        return response()->json([
            'success' => false,
            'message' => 'JSON request body is too large.',
        ], 413);
    }
}
