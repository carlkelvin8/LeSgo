<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Http;

class GoogleIdentityVerifier
{
    public function verify(string $token): ?array
    {
        $clientId = config('services.google.client_id');
        if (!$clientId) {
            return null;
        }
        try {
            $response = Http::timeout(10)->get('https://oauth2.googleapis.com/tokeninfo', ['id_token' => $token]);
            if (!$response->successful()) {
                return null;
            }
            $identity = $response->json();
            if (!is_array($identity) || ($identity['aud'] ?? null) !== $clientId
                || empty($identity['sub']) || empty($identity['email'])
                || !filter_var($identity['email_verified'] ?? false, FILTER_VALIDATE_BOOL)) {
                return null;
            }
            return $identity;
        } catch (\Throwable $e) {
            return null;
        }
    }

    public function matches(User $user, string $token): bool
    {
        $identity = $this->verify($token);
        return $identity !== null && !empty($user->google_id)
            && hash_equals((string) $user->google_id, (string) $identity['sub'])
            && strcasecmp($user->email, $identity['email']) === 0;
    }
}
