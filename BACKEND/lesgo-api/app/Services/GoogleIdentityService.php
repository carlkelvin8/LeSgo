<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GoogleIdentityService
{
    /**
     * Verify a Google ID token and return its identity claims.
     *
     * @return array<string, mixed>|null
     */
    public function verifyIdToken(string $idToken): ?array
    {
        $clientId = trim((string) config('services.google.client_id'));
        if ($clientId === '') {
            Log::error('Google identity verification is unavailable: GOOGLE_CLIENT_ID is not configured.');

            return null;
        }

        try {
            $response = Http::timeout(10)->get(
                'https://oauth2.googleapis.com/tokeninfo',
                ['id_token' => $idToken]
            );

            if (! $response->successful()) {
                Log::warning('Google token verification failed', [
                    'status' => $response->status(),
                ]);

                return null;
            }

            $payload = $response->json();
            if (! is_array($payload)) {
                return null;
            }

            $audienceMatches = isset($payload['aud'])
                && hash_equals($clientId, (string) $payload['aud']);
            $hasIdentity = ! empty($payload['sub']) && ! empty($payload['email']);
            $emailVerified = filter_var(
                $payload['email_verified'] ?? false,
                FILTER_VALIDATE_BOOL
            );

            if (! $audienceMatches || ! $hasIdentity || ! $emailVerified) {
                Log::warning('Google token claims rejected', [
                    'audience_matches' => $audienceMatches,
                    'has_identity' => $hasIdentity,
                    'email_verified' => $emailVerified,
                ]);

                return null;
            }

            return $payload;
        } catch (\Throwable $e) {
            Log::error('Google token verification error', [
                'error' => $e->getMessage(),
            ]);

            return null;
        }
    }
}
