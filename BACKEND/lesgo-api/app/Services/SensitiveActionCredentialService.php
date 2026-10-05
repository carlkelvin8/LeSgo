<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;

class SensitiveActionCredentialService
{
    public function __construct(
        private GoogleIdentityService $googleIdentityService,
    ) {}

    public function verify(
        User $user,
        ?string $password = null,
        ?string $googleIdToken = null,
    ): bool {
        if ($password !== null && $password !== '') {
            return Hash::check($password, $user->password);
        }

        if ($googleIdToken === null || $googleIdToken === '' || ! $user->google_id) {
            return false;
        }

        $identity = $this->googleIdentityService->verifyIdToken($googleIdToken);
        if (! $identity) {
            return false;
        }

        $subjectMatches = hash_equals(
            (string) $user->google_id,
            (string) ($identity['sub'] ?? '')
        );
        $emailMatches = strcasecmp(
            (string) $user->email,
            (string) ($identity['email'] ?? '')
        ) === 0;

        return $subjectMatches && $emailMatches;
    }
}
