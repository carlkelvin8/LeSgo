<?php

namespace Tests\Feature;

use App\Models\DriverProfile;
use App\Models\Order;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class DeliveryProofRequiredTest extends TestCase
{
    private function pickedUpOrder(): Order
    {
        Queue::fake();
        $driver = $this->actingAsRole('driver');
        $profile = DriverProfile::factory()->create(['user_id' => $driver->id]);
        $this->activatePartner($driver);
        return Order::factory()->create([
            'driver_id' => $profile->id,
            'status' => 'picked_up',
            'picked_up_at' => now(),
            'proof_images' => [],
        ]);
    }

    public function test_completion_without_uploaded_proof_does_not_change_order_or_payment(): void
    {
        $order = $this->pickedUpOrder();
        $this->patchJson("/api/v1/orders/{$order->id}/status", [
            'status' => 'completed',
            'proof_images' => ['client-only-photo.jpg'],
        ])->assertStatus(422);
        $order->refresh();
        $this->assertSame('picked_up', $order->status);
        $this->assertNull($order->completed_at);
        $this->assertSame('pending', $order->payment_status);
    }

    public function test_blank_proof_entries_do_not_allow_completion(): void
    {
        $order = $this->pickedUpOrder();
        $order->update(['proof_images' => ['', '   ', null]]);
        $this->patchJson("/api/v1/orders/{$order->id}/status", ['status' => 'completed'])
            ->assertStatus(422);
        $this->assertSame('picked_up', $order->fresh()->status);
    }

    public function test_uploaded_photo_allows_completion(): void
    {
        $order = $this->pickedUpOrder();
        config([
            'filesystems.media_disk' => 's3',
            'filesystems.disks.s3.key' => 'test-key',
            'filesystems.disks.s3.secret' => 'test-secret',
            'filesystems.disks.s3.bucket' => 'test-bucket',
            'filesystems.disks.s3.url' => 'https://media.example.test',
        ]);
        Storage::fake('s3');
        $this->postJson("/api/v1/orders/{$order->id}/upload-proof", [
            'images' => [UploadedFile::fake()->image('delivery.jpg')],
        ])->assertOk();
        $this->assertNotEmpty($order->fresh()->proof_images);
        $this->patchJson("/api/v1/orders/{$order->id}/status", ['status' => 'completed'])
            ->assertOk()->assertJsonPath('data.status', 'completed');
        $this->assertNotNull($order->fresh()->completed_at);
    }
}
