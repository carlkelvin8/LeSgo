<?php

namespace Tests;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

abstract class TestCase extends BaseTestCase
{
    use RefreshDatabase;

    // ── Auth helpers ──────────────────────────────────────────────────────────

    protected function actingAsRole(string $role): User
    {
        $user = User::factory()->create(['role' => $role]);
        $this->actingAs($user, 'sanctum');
        return $user;
    }

    protected function tokenFor(User $user): string
    {
        return $user->createToken('test')->plainTextToken;
    }

    /** Explicit prerequisite for tests exercising operational partner APIs. */
    protected function activatePartner(User $user): void
    {
        $fee = \App\Services\RegistrationFeeService::ensurePaymentRecord($user);
        $fee->update(['payment_status' => 'paid', 'payment_date' => now(), 'application_status' => 'approved']);
        \App\Services\RegistrationFeeService::tryActivate($fee->fresh());
        $user->refresh();
    }

    /** @param array<string, mixed> $data */
    protected function withCustomerIdentity(array $data): array
    {
        config([
            'filesystems.media_disk' => 's3',
            'filesystems.disks.s3.key' => 'test-key',
            'filesystems.disks.s3.secret' => 'test-secret',
            'filesystems.disks.s3.bucket' => 'test-bucket',
            'filesystems.disks.s3.url' => 'https://media.example.test',
        ]);
        Storage::fake('s3');

        return array_merge($data, [
            'id_type' => 'philippine_national_id',
            'id_number' => '1234-5678-9012-3456',
            'selfie' => UploadedFile::fake()->image('selfie.jpg'),
            'valid_id_front' => UploadedFile::fake()->image('id-front.jpg'),
            'valid_id_back' => UploadedFile::fake()->image('id-back.jpg'),
        ]);
    }

    // ── Response assertion helpers ────────────────────────────────────────────

    protected function assertApiSuccess($response, int $status = 200): void
    {
        $response->assertStatus($status)
                 ->assertJsonPath('success', true);
    }

    protected function assertApiError($response, int $status): void
    {
        $response->assertStatus($status)
                 ->assertJsonPath('success', false);
    }

    protected function assertPaginated($response): void
    {
        $response->assertJsonStructure([
            'success', 'data', 'meta' => ['total', 'per_page', 'current_page', 'last_page'],
        ]);
    }
}
