<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\DriverProfile;
use App\Models\RatingReview;
use App\Models\Service;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RatingReviewSecurityTest extends TestCase
{
    use RefreshDatabase;

    public function test_customer_can_review_completed_order_using_server_owned_order_identity(): void
    {
        $customer = User::factory()->create();
        $driverProfile = DriverProfile::factory()->create();
        $driver = $driverProfile->user;
        $service = Service::factory()->create();
        $order = Order::factory()->completed()->create([
            'customer_id' => $customer->id,
            'driver_id' => $driverProfile->id,
            'service_id' => $service->id,
        ]);

        $this->actingAs($customer, 'sanctum')->postJson('/api/v1/reviews', [
            'order_id' => $order->id,
            'overall_rating' => 5,
            'review_comment' => 'Great service',
            'driver_id' => User::factory()->create()->id,
            'service_id' => Service::factory()->create()->id,
            'status' => 'approved',
            'is_verified' => false,
        ])->assertCreated()
            ->assertJsonPath('data.driver_id', $driver->id)
            ->assertJsonPath('data.service_id', $service->id)
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.is_verified', true);

        $this->assertDatabaseHas('ratings_reviews', [
            'order_id' => $order->id,
            'user_id' => $customer->id,
            'driver_id' => $driver->id,
            'service_id' => $service->id,
            'status' => 'pending',
        ]);
    }

    public function test_customer_cannot_review_someone_elses_completed_order(): void
    {
        $order = Order::factory()->completed()->create();
        $this->actingAs(User::factory()->create(), 'sanctum')->postJson('/api/v1/reviews', [
            'order_id' => $order->id,
            'overall_rating' => 5,
        ])->assertForbidden();

        $this->assertSame(0, RatingReview::count());
    }

    public function test_completed_order_can_only_be_reviewed_once(): void
    {
        $customer = User::factory()->create();
        $order = Order::factory()->completed()->create(['customer_id' => $customer->id]);
        $payload = ['order_id' => $order->id, 'overall_rating' => 4];

        $this->actingAs($customer, 'sanctum')->postJson('/api/v1/reviews', $payload)->assertCreated();
        $this->postJson('/api/v1/reviews', $payload)->assertStatus(409);
        $this->assertSame(1, RatingReview::where('order_id', $order->id)->count());
    }
}
