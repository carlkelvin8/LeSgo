<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

/** Opaque registration credential issued only after server-side OTP verification. */
class RegistrationPhoneProof
{
    public static function normalize(string $phone): string
    {
        $digits = preg_replace('/\D/', '', $phone);
        if (str_starts_with($digits, '09') && strlen($digits) === 11) {
            $digits = '63'.substr($digits, 1);
        } elseif (str_starts_with($digits, '9') && strlen($digits) === 10) {
            $digits = '63'.$digits;
        }
        return '+'.$digits;
    }

    public static function issue(string $phone): string
    {
        $token = Str::random(64);
        DB::table('registration_phone_proofs')->insert([
            'token_hash' => hash('sha256', $token),
            'phone' => self::normalize($phone),
            'expires_at' => now()->addMinutes(10),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        return $token;
    }

    /** Call inside the account-creation transaction; failure rolls back consumption. */
    public static function consume(string $phone, string $token): void
    {
        $proof = DB::table('registration_phone_proofs')
            ->where('token_hash', hash('sha256', $token))->lockForUpdate()->first();
        if (!$proof || $proof->phone !== self::normalize($phone)
            || $proof->consumed_at !== null || now()->gte($proof->expires_at)) {
            throw ValidationException::withMessages([
                'phone_verification_token' => 'Verify this phone number again before registering.',
            ]);
        }
        DB::table('registration_phone_proofs')->where('id', $proof->id)
            ->update(['consumed_at' => now(), 'updated_at' => now()]);
    }
}
