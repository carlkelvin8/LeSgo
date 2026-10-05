<?php

namespace Tests\Feature;

use App\Jobs\AutoAssignDriverJob;
use App\Jobs\NotifyNearbyDriversNewOrderJob;
use App\Jobs\ProcessPaymentWebhookJob;
use App\Models\Order;
use App\Models\Payment;
use App\Models\Service;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class WebhookTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Queue::fake();
    }

    private function createPendingPayment(): Payment
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $service = Service::factory()->create();
        $order = Order::factory()->create(['customer_id' => $customer->id, 'service_id' => $service->id]);

        return Payment::factory()->create([
            'order_id' => $order->id,
            'customer_id' => $customer->id,
            'provider' => 'xendit',
            'provider_reference' => 'inv_test_123',
            'amount' => 100,
        ]);
    }

    public function test_xendit_webhook_dispatches_job(): void
    {
        config(['services.xendit.webhook_token' => 'correct-token']);

        $this->postJson('/api/v1/webhooks/payments/xendit', [
            'id' => 'inv_test_123',
            'status' => 'PAID',
        ], ['X-CALLBACK-TOKEN' => 'correct-token'])->assertStatus(200);

        Queue::assertPushed(ProcessPaymentWebhookJob::class);
    }

    public function test_xendit_webhook_rejected_with_wrong_token(): void
    {
        config(['services.xendit.webhook_token' => 'correct-token']);

        $this->postJson('/api/v1/webhooks/payments/xendit', [
            'id' => 'inv_test_123',
            'status' => 'PAID',
        ], ['X-CALLBACK-TOKEN' => 'wrong-token'])->assertStatus(400);
    }

    public function test_xendit_webhook_accepted_with_correct_token(): void
    {
        config(['services.xendit.webhook_token' => 'correct-token']);

        $this->postJson('/api/v1/webhooks/payments/xendit', [
            'id' => 'inv_test_123',
            'status' => 'PAID',
        ], ['X-CALLBACK-TOKEN' => 'correct-token'])->assertStatus(200);

        Queue::assertPushed(ProcessPaymentWebhookJob::class);
    }

    public function test_webhook_job_marks_payment_as_paid(): void
    {
        $payment = $this->createPendingPayment();

        $job = new ProcessPaymentWebhookJob('xendit', [
            'id' => 'inv_test_123',
            'status' => 'PAID',
            'amount' => 100,
            'currency' => 'PHP',
        ]);

        $job->handle();

        $this->assertDatabaseHas('payments', [
            'id' => $payment->id,
            'status' => 'paid',
        ]);
    }

    public function test_paid_webhook_releases_online_order_to_driver_dispatch(): void
    {
        Queue::fake();
        $payment = $this->createPendingPayment();
        $payment->order()->update([
            'payment_method' => 'xendit',
            'payment_status' => 'pending',
        ]);

        (new ProcessPaymentWebhookJob('xendit', [
            'id' => 'inv_test_123',
            'status' => 'PAID',
            'amount' => 100,
            'currency' => 'PHP',
        ]))->handle();

        $this->assertSame('paid', $payment->order->fresh()->payment_status);
        Queue::assertPushed(NotifyNearbyDriversNewOrderJob::class, 1);
        Queue::assertPushed(AutoAssignDriverJob::class, 1);
    }

    public function test_paid_webhook_with_mismatched_amount_is_rejected(): void
    {
        $payment = $this->createPendingPayment();

        (new ProcessPaymentWebhookJob('xendit', [
            'id' => 'inv_test_123',
            'status' => 'PAID',
            'amount' => 0.01,
            'currency' => 'PHP',
        ]))->handle();

        $this->assertSame('pending', $payment->fresh()->status);
        $this->assertSame('pending', $payment->order->fresh()->payment_status);
    }

    public function test_late_paid_webhook_does_not_reopen_cancelled_order(): void
    {
        Queue::fake();
        $payment = $this->createPendingPayment();
        $payment->order()->update(['status' => 'cancelled', 'payment_status' => 'failed']);

        (new ProcessPaymentWebhookJob('xendit', [
            'id' => 'inv_test_123',
            'status' => 'PAID',
            'amount' => 100,
            'currency' => 'PHP',
        ]))->handle();

        $this->assertSame('paid', $payment->fresh()->status);
        $this->assertSame('cancelled', $payment->order->fresh()->status);
        $this->assertSame('failed', $payment->order->fresh()->payment_status);
        $this->assertTrue($payment->order->fresh()->meta['late_payment_review_required']);
        Queue::assertNotPushed(NotifyNearbyDriversNewOrderJob::class);
        Queue::assertNotPushed(AutoAssignDriverJob::class);
    }

    public function test_webhook_job_marks_payment_as_failed(): void
    {
        $payment = $this->createPendingPayment();

        $job = new ProcessPaymentWebhookJob('xendit', [
            'id' => 'inv_test_123',
            'status' => 'EXPIRED',
        ]);

        $job->handle();

        $this->assertDatabaseHas('payments', [
            'id' => $payment->id,
            'status' => 'failed',
        ]);
    }

    public function test_webhook_job_is_idempotent(): void
    {
        $payment = $this->createPendingPayment();
        $payment->update(['status' => 'paid', 'paid_at' => now()]);

        $job = new ProcessPaymentWebhookJob('xendit', [
            'id' => 'inv_test_123',
            'status' => 'PAID',
            'amount' => 100,
            'currency' => 'PHP',
        ]);

        $job->handle(); // second call — should not throw or double-process

        $this->assertDatabaseHas('payments', ['id' => $payment->id, 'status' => 'paid']);
    }

    public function test_stale_failed_event_cannot_regress_a_paid_payment(): void
    {
        $payment = $this->createPendingPayment();
        $payment->update(['status' => 'paid', 'paid_at' => now()]);
        $payment->order()->update(['payment_status' => 'paid']);

        (new ProcessPaymentWebhookJob('xendit', [
            'id' => 'inv_test_123',
            'status' => 'EXPIRED',
        ]))->handle();

        $this->assertSame('paid', $payment->fresh()->status);
        $this->assertSame('paid', $payment->order->fresh()->payment_status);
    }

    public function test_replayed_paid_event_cannot_regress_a_refunded_payment(): void
    {
        $payment = $this->createPendingPayment();
        $payment->update(['status' => 'refunded']);
        $payment->order()->update(['payment_status' => 'refunded']);

        (new ProcessPaymentWebhookJob('xendit', [
            'id' => 'inv_test_123',
            'status' => 'PAID',
            'amount' => 100,
            'currency' => 'PHP',
        ]))->handle();

        $this->assertSame('refunded', $payment->fresh()->status);
        $this->assertSame('refunded', $payment->order->fresh()->payment_status);
    }

    public function test_invalid_provider_route_returns_404(): void
    {
        $this->postJson('/api/v1/webhooks/payments/stripe', ['id' => 'x'])
            ->assertStatus(404);
    }

    public function test_duplicate_paid_callbacks_dispatch_only_once(): void
    {
        $payment = $this->createPendingPayment();
        $payment->order()->update(['payment_method' => 'gcash', 'payment_status' => 'pending']);
        $job = new ProcessPaymentWebhookJob('xendit', ['id' => 'inv_test_123', 'status' => 'PAID', 'amount' => 100, 'currency' => 'PHP']);
        $job->handle();
        $job->handle();
        Queue::assertPushed(NotifyNearbyDriversNewOrderJob::class, 1);
        Queue::assertPushed(AutoAssignDriverJob::class, 1);
    }

    public function test_paid_callback_does_not_dispatch_future_or_cancelled_orders(): void
    {
        $payment = $this->createPendingPayment();
        $payment->order()->update(['payment_method' => 'gcash', 'payment_status' => 'pending',
            'status' => 'scheduled', 'scheduled_delivery_time' => now()->addHour()]);
        (new ProcessPaymentWebhookJob('xendit', ['id' => 'inv_test_123', 'status' => 'PAID', 'amount' => 100, 'currency' => 'PHP']))->handle();
        $this->assertSame('paid', $payment->order->fresh()->payment_status);
        Queue::assertNotPushed(NotifyNearbyDriversNewOrderJob::class);
        Queue::assertNotPushed(AutoAssignDriverJob::class);
        $payment->update(['status' => 'pending']);
        $payment->order()->update(['status' => 'cancelled', 'payment_status' => 'pending', 'scheduled_delivery_time' => null]);
        (new ProcessPaymentWebhookJob('xendit', ['id' => 'inv_test_123', 'status' => 'PAID', 'amount' => 100, 'currency' => 'PHP']))->handle();
        Queue::assertNotPushed(NotifyNearbyDriversNewOrderJob::class);
        Queue::assertNotPushed(AutoAssignDriverJob::class);
    }

    public function test_provider_reference_cannot_modify_another_providers_payment(): void
    {
        $payment = $this->createPendingPayment();
        (new ProcessPaymentWebhookJob('paymongo', ['id' => 'inv_test_123', 'status' => 'PAID']))->handle();
        $this->assertSame('pending', $payment->fresh()->status);
    }

    public function test_refund_updates_both_payment_and_order(): void
    {
        $payment = $this->createPendingPayment();
        $payment->update(['status' => 'paid']);
        $payment->order()->update(['payment_status' => 'paid']);
        (new ProcessPaymentWebhookJob('xendit', ['id' => 'inv_test_123', 'status' => 'REFUNDED']))->handle();
        $this->assertSame('refunded', $payment->fresh()->status);
        $this->assertSame('refunded', $payment->order->fresh()->payment_status);
    }
}
