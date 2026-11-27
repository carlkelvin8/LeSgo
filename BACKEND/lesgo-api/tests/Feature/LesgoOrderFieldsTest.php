<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Service;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class LesgoOrderFieldsTest extends TestCase
{
    public function test_lesgo_order_stores_top_level_item_description_and_estimated_weight(): void
    {
        Queue::fake();
        $service = Service::factory()->create(['code' => 'LESGO']);
        $this->actingAsRole('customer');

        $response = $this->postJson('/api/v1/orders', [
            'service_id' => $service->id,
            'pickup' => ['address' => '123 Rizal St', 'lat' => 14.5995, 'lng' => 120.9842],
            'dropoff' => ['address' => '456 Mabini Ave', 'lat' => 14.6090, 'lng' => 121.0000],
            'estimated_distance_m' => 5000,
            'payment_method' => 'cash',
            'item_description' => 'Books and clothes',
            'estimated_weight_kg' => 3.5,
        ])->assertCreated();

        $order = Order::findOrFail($response->json('data.id'));
        $this->assertSame('Books and clothes', $order->item_description);
        $this->assertEquals(3.5, (float) $order->estimated_weight_kg);
        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'item_description' => 'Books and clothes',
            'estimated_weight_kg' => 3.5,
        ]);
    }
}
