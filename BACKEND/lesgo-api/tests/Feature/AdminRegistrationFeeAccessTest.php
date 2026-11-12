<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminRegistrationFeeAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_list_registration_fees(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'admin']));

        $this->getJson('/api/v1/admin/registration-fees')->assertOk();
        $this->getJson('/api/v1/admin/vouchers')->assertOk();
        $this->getJson('/api/v1/admin/mission-templates')->assertOk();
    }

    public function test_non_admin_is_forbidden_from_admin_registration_fee_endpoints(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'customer']));

        $this->getJson('/api/v1/admin/registration-fees')->assertForbidden();
    }
}
