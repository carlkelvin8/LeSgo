<?php

namespace App\Jobs;

use App\Models\Payment;
use App\Models\PaymentRefund;
use App\Services\PaymentGatewayManager;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProcessCancelledGatewayRefundJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;

    public function __construct(public readonly int $refundId) {}

    public function handle(PaymentGatewayManager $gateway): void
    {
        $refundRecord = PaymentRefund::query()->find($this->refundId);
        if (! $refundRecord || in_array($refundRecord->status, ['completed', 'failed'], true)) {
            return;
        }

        $payment = Payment::query()->find($refundRecord->payment_id);
        if (! $payment || ! $refundRecord->payment_reference) {
            $refundRecord->update([
                'status' => 'verification_required',
                'failure_reason' => 'The original gateway payment reference is unavailable.',
            ]);
            return;
        }

        $result = $gateway->createRefund(
            $refundRecord->payment_reference,
            (float) $refundRecord->amount,
            $refundRecord->reason,
            $refundRecord->provider,
            $refundRecord->idempotency_key,
        );

        $providerStatus = strtoupper((string) ($result['status'] ?? ''));
        $status = match ($providerStatus) {
            'SUCCEEDED', 'COMPLETED', 'REFUNDED' => 'completed',
            'FAILED', 'REJECTED', 'CANCELLED' => 'failed',
            default => 'submitted',
        };

        DB::transaction(function () use ($refundRecord, $payment, $result, $providerStatus, $status): void {
            $lockedRefund = PaymentRefund::query()->whereKey($refundRecord->id)->lockForUpdate()->firstOrFail();
            if (in_array($lockedRefund->status, ['completed', 'failed'], true)) {
                return;
            }

            $lockedRefund->update([
                'gateway_reference' => $result['id'] ?? null,
                'status' => $status,
                'completed_at' => $status === 'completed' ? now() : null,
                'failure_reason' => $status === 'failed'
                    ? (string) ($result['message'] ?? 'Gateway rejected the refund.')
                    : null,
                'meta' => array_merge($lockedRefund->meta ?? [], ['gateway_status' => $providerStatus]),
            ]);

            if ($status === 'completed') {
                $lockedPayment = Payment::query()->whereKey($payment->id)->lockForUpdate()->firstOrFail();
                $completed = (float) PaymentRefund::query()
                    ->where('payment_id', $lockedPayment->id)
                    ->where('status', 'completed')
                    ->sum('amount');
                if ($completed + 0.01 >= (float) $lockedPayment->amount) {
                    $lockedPayment->update(['status' => 'refunded']);
                    $lockedPayment->order()->update(['payment_status' => 'refunded']);
                }
            }
        });
    }

    public function failed(\Throwable $exception): void
    {
        PaymentRefund::query()->whereKey($this->refundId)
            ->whereIn('status', ['processing', 'submitted'])
            ->update([
                'status' => 'verification_required',
                'failure_reason' => 'Automatic refund needs reconciliation. The order remains cancelled.',
            ]);

        Log::error('Cancelled order gateway refund needs reconciliation', [
            'refund_id' => $this->refundId,
            'error' => $exception->getMessage(),
        ]);
    }
}
