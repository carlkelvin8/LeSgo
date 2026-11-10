<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Partner;
use App\Models\RatingReview;
use App\Models\User;
use App\Services\RegistrationFeeService;
use Tests\TestCase;

class MerchantApiShapeTest extends TestCase
{
    public function test_empty_opening_hours_read_as_null(): void
    {
        $partner = Partner::factory()->create(['opening_hours' => []]);

        $this->assertNull($partner->fresh()->opening_hours);
        $this->assertNull($partner->fresh()->toArray()['opening_hours']);
    }

    public function test_set_opening_hours_are_kept(): void
    {
        $hours = ['monday' => ['open' => '08:00', 'close' => '17:00']];
        $partner = Partner::factory()->create(['opening_hours' => $hours]);

        $this->assertSame($hours, $partner->fresh()->opening_hours);
    }

    private function reviewFor(Partner $partner, int $rating): void
    {
        $order = Order::factory()->create(['partner_id' => $partner->id]);
        RatingReview::create([
            'order_id' => $order->id,
            'user_id' => $order->customer_id,
            'overall_rating' => $rating,
            'status' => 'approved',
        ]);
    }

    public function test_partner_statistics_count_only_that_store(): void
    {
        $store = Partner::factory()->create();
        $this->reviewFor($store, 5);
        $this->reviewFor($store, 3);
        $this->reviewFor(Partner::factory()->create(), 1);

        $owner = User::factory()->create(['role' => 'partner_admin']);
        $store->update(['user_id' => $owner->id]);
        RegistrationFeeService::ensurePaymentRecord($owner)->update([
            'payment_status' => 'waived', 'waived_at' => now(), 'application_status' => 'approved', 'is_active' => true,
        ]);

        $this->actingAs($owner, 'sanctum')
            ->getJson("/api/v1/reviews/statistics?reviewable_type=partner&reviewable_id={$store->id}")
            ->assertOk()
            ->assertJsonPath('data.total_reviews', 2)
            ->assertJsonPath('data.rating_distribution.5', 1)
            ->assertJsonPath('data.rating_distribution.3', 1)
            ->assertJsonPath('data.rating_distribution.1', 0);
    }
}
