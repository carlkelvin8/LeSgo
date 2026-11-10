<?php

namespace Tests\Feature;

use App\Models\DriverProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class DriverLoginWithoutPlateTest extends TestCase
{
    use RefreshDatabase;

    public function test_new_driver_without_a_plate_number_can_log_in(): void
    {
        $driver = User::factory()->driver()->create([
            'password' => Hash::make('Secret123!'),
        ]);
        DriverProfile::factory()->create([
            'user_id' => $driver->id,
            'plate_number' => null,
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email' => $driver->email,
            'password' => 'Secret123!',
        ])->assertOk()
            ->assertJsonPath('user.driver_profile.plate_number', null);
    }
}
