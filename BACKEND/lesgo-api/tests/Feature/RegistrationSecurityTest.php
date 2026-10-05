<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Partner;
use App\Models\DriverProfile;
use App\Services\RegistrationPhoneProof;
use App\Services\RegistrationFeeService;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class RegistrationSecurityTest extends TestCase
{
    private function payload(bool $rider): array
    {
        config(['filesystems.media_disk' => 's3', 'filesystems.disks.s3.key' => 'test',
            'filesystems.disks.s3.secret' => 'test', 'filesystems.disks.s3.bucket' => 'test']);
        Storage::fake('s3');
        $data = ['name' => 'New Applicant', 'email' => 'applicant@example.test',
            'password' => 'SecurePass123!', 'password_confirmation' => 'SecurePass123!',
            'phone_number' => '+639171234567', 'phone' => '+639171234567',
            'terms_accepted' => true, 'privacy_accepted' => true];
        $fields = $rider ? ['selfie', 'selfie_with_motorcycle', 'resume', 'barangay_clearance',
            'drivers_license', 'motorcycle_orcr', 'scanned_orcr', 'digital_signature']
            : ['selfie', 'valid_id', 'digital_signature', 'barangay_permit', 'mayors_permit', 'dti_permit'];
        foreach ($fields as $field) {
            $data[$field] = UploadedFile::fake()->create($field.'.pdf', 10, 'application/pdf');
        }
        return array_merge($data, $rider ? ['license_number' => 'N01-TEST-123']
            : ['role' => 'partner_admin', 'restaurant_name' => 'New Store']);
    }

    public function test_rider_cannot_use_generic_registration_to_bypass_documents_and_otp(): void
    {
        $this->postJson('/api/v1/auth/register', ['role' => 'driver'])
            ->assertUnprocessable()->assertJsonValidationErrors('role');
    }

    public function test_both_registration_endpoints_require_proof_and_terms(): void
    {
        foreach ([false, true] as $rider) {
            $data = $this->payload($rider);
            unset($data['terms_accepted']);
            $this->post($rider ? '/api/v1/drivers/register' : '/api/v1/auth/register', $data,
                ['Accept' => 'application/json'])->assertUnprocessable()
                ->assertJsonValidationErrors(['phone_verification_token', 'terms_accepted']);
        }
        $this->assertDatabaseCount('users', 0);
    }

    public function test_new_merchant_and_rider_are_verified_but_restricted_until_paid_and_approved(): void
    {
        foreach ([false, true] as $rider) {
            $data = $this->payload($rider);
            $data['email'] = $rider ? 'rider@example.test' : 'merchant@example.test';
            $data['phone'] = $data['phone_number'] = $rider ? '+639181234567' : '+639171234567';
            $proof = RegistrationPhoneProof::issue($data['phone']);
            $data['phone_verification_token'] = $proof;
            $response = $this->post($rider ? '/api/v1/drivers/register' : '/api/v1/auth/register',
                $data, ['Accept' => 'application/json'])->assertCreated();
            $response->assertJsonPath(($rider ? 'data.user' : 'user').'.registration_fee.is_active', false);
            $user = User::where('email', $data['email'])->sole();
            $this->assertNotNull($user->phone_verified_at);
            $this->assertFalse(RegistrationFeeService::canAccessOperationalFeatures($user));
            $this->assertNotNull(DB::table('registration_phone_proofs')->where('token_hash', hash('sha256', $proof))->value('consumed_at'));
            $this->assertDatabaseMissing('registration_phone_proofs', ['token_hash' => $proof]);
        }
    }

    public function test_mismatched_expired_and_replayed_proofs_cannot_create_accounts(): void
    {
        foreach ([false, true] as $rider) {
            foreach (['mismatch', 'expired', 'replayed'] as $case) {
                $data = $this->payload($rider);
                $proof = RegistrationPhoneProof::issue($case === 'mismatch' ? '+639181234567' : $data['phone']);
                if ($case === 'expired') {
                    DB::table('registration_phone_proofs')->where('token_hash', hash('sha256', $proof))->update(['expires_at' => now()->subMinute()]);
                } elseif ($case === 'replayed') {
                    DB::transaction(fn () => RegistrationPhoneProof::consume($data['phone'], $proof));
                }
                $data['phone_verification_token'] = $proof;
                $this->post($rider ? '/api/v1/drivers/register' : '/api/v1/auth/register', $data,
                    ['Accept' => 'application/json'])->assertUnprocessable()->assertJsonValidationErrors('phone_verification_token');
            }
        }
        $this->assertDatabaseCount('users', 0);
    }

    public function test_operational_access_requires_both_payment_and_approval(): void
    {
        foreach (['driver', 'partner_admin'] as $role) {
            $user = User::factory()->create(['role' => $role]);
            if ($role === 'driver') {
                DriverProfile::factory()->create(['user_id' => $user->id, 'status' => 'pending']);
                $paths = ['/api/v1/orders'];
            } else {
                $partner = Partner::factory()->create(['user_id' => $user->id, 'status' => 'pending']);
                $paths = ['/api/v1/orders', "/api/v1/partners/{$partner->id}/merchant-menu",
                    "/api/v1/partners/{$partner->id}/staff"];
            }
            $this->actingAs($user, 'sanctum');
            foreach ($paths as $path) {
                $this->getJson($path)->assertForbidden()->assertJsonPath('error_code', 'REGISTRATION_NOT_ACTIVE');
            }
            $fee = RegistrationFeeService::ensurePaymentRecord($user);
            $fee->update(['payment_status' => 'paid', 'payment_date' => now()]);
            foreach ($paths as $path) {
                $this->getJson($path)->assertForbidden()->assertJsonPath('error_code', 'REGISTRATION_NOT_ACTIVE');
            }
            RegistrationFeeService::approveApplication($fee->fresh(), User::factory()->create(['role' => 'admin']));
            $this->getJson('/api/v1/orders')->assertOk();
        }
    }

    public function test_staff_cannot_bypass_the_merchant_fee(): void
    {
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $partner = Partner::factory()->create(['user_id' => $owner->id, 'status' => 'active']);
        $staff = User::factory()->create(['role' => 'partner_staff']);
        \App\Models\PartnerStaff::create(['partner_id' => $partner->id,
            'user_id' => $staff->id, 'role' => 'admin', 'is_active' => true]);
        $this->actingAs($staff, 'sanctum')->getJson('/api/v1/orders')
            ->assertForbidden()->assertJsonPath('error_code', 'REGISTRATION_NOT_ACTIVE');
        $fee = RegistrationFeeService::ensurePaymentRecord($owner);
        $fee->update(['payment_status' => 'paid', 'payment_date' => now(), 'application_status' => 'approved']);
        $this->assertTrue(RegistrationFeeService::getStatusForUser($staff)['can_access_operational_features']);
    }
}
