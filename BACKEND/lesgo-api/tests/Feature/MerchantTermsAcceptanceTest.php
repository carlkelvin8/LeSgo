<?php

namespace Tests\Feature;

use Tests\TestCase;

class MerchantTermsAcceptanceTest extends TestCase
{
    public function test_merchant_registration_rejects_missing_or_declined_terms(): void
    {
        foreach ([null, false] as $accepted) {
            $payload = [
                'role' => 'partner_admin',
                'name' => 'Merchant Applicant',
                'email' => 'merchant-consent@example.test',
                'password' => 'SecurePass123!',
                'password_confirmation' => 'SecurePass123!',
                'restaurant_name' => 'Test Store',
                'privacy_accepted' => true,
            ];
            if ($accepted !== null) {
                $payload['terms_accepted'] = $accepted;
            }

            $this->postJson('/api/v1/auth/register', $payload)
                ->assertStatus(422)
                ->assertJsonValidationErrors('terms_accepted');

            $this->assertDatabaseMissing('users', ['email' => $payload['email']]);
            $this->assertDatabaseCount('registration_fee_payments', 0);
        }
    }
}
