<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StorePaymentRequest;
use App\Jobs\ProcessPaymentWebhookJob;
use App\Models\Order;
use App\Models\Payment;
use App\Services\CacheService;
use App\Services\OrderWalletPaymentService;
use App\Services\PayMongoService;
use App\Services\PaymentGatewayService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    /**
     * @OA\Get(
     *     path="/api/v1/payments",
     *     summary="List payments (scoped by role)",
     *     tags={"Payments"},
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(name="order_id", in="query", required=false, @OA\Schema(type="integer")),
     *     @OA\Parameter(name="status", in="query", required=false, @OA\Schema(type="string", enum={"pending","paid","failed","refunded"})),
     *     @OA\Response(response=200, description="Paginated payments",
     *         @OA\JsonContent(
     *             @OA\Property(property="data", type="array", @OA\Items(ref="#/components/schemas/Payment")),
     *             @OA\Property(property="meta", ref="#/components/schemas/PaginationMeta"),
     *             @OA\Property(property="links", ref="#/components/schemas/PaginationLinks")
     *         )
     *     ),
     *     @OA\Response(response=403, ref="#/components/schemas/ErrorResponse")
     * )
     */
    public function index(Request $request): JsonResponse
    {
        $user    = $request->user();
        $orderId = $request->query('order_id');
        $status  = $request->query('status');

        if ($orderId && !$user->isAdmin()) {
            $ownsOrder = Order::where('id', $orderId)
                ->where('customer_id', $user->id)
                ->exists();

            if (!$ownsOrder) {
                return $this->error('Forbidden', 403);
            }
        }

        $scopeId  = $user->isAdmin() ? 'admin' : "user:{$user->id}";
        $cacheKey = "payments:{$scopeId}:list:" . md5("{$orderId}:{$status}");

        $paginator = CacheService::remember($cacheKey, CacheService::CACHE_SHORT, function () use ($user, $orderId, $status) {
            $query = Payment::query()->with([
                'order:id,customer_id,service_id,status,payment_method,estimated_fare',
                'customer:id,name,email,phone_number',
            ]);

            if (!$user->isAdmin()) {
                $query->where('customer_id', $user->id);
            }

            if ($orderId) {
                $query->where('order_id', $orderId);
            }

            if ($status) {
                $query->where('status', $status);
            }

            return $query->orderByDesc('id')->paginate(20);
        });

        return $this->success($paginator);
    }

    /**
     * @OA\Post(
     *     path="/api/v1/payments",
     *     summary="Record a payment",
     *     tags={"Payments"},
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(required=true,
     *         @OA\JsonContent(required={"order_id","customer_id","amount","method"},
     *             @OA\Property(property="order_id", type="integer", example=10),
     *             @OA\Property(property="customer_id", type="integer", example=5),
     *             @OA\Property(property="amount", type="number", format="float", example=85.50),
     *             @OA\Property(property="currency", type="string", example="PHP"),
     *             @OA\Property(property="method", type="string", enum={"cash","gcash","maya","card","wallet"}, example="gcash")
     *         )
     *     ),
     *     @OA\Response(response=201, description="Payment recorded",
     *         @OA\JsonContent(@OA\Property(property="data", ref="#/components/schemas/Payment"))
     *     ),
     *     @OA\Response(response=403, ref="#/components/schemas/ErrorResponse"),
     *     @OA\Response(response=409, description="Order already paid")
     * )
     */
    public function store(StorePaymentRequest $request): JsonResponse
    {
        $data = $request->validated();
        $user = $request->user();

        $order = Order::find($data['order_id']);

        if (!$order) {
            return $this->error('Order not found.', 404);
        }

        // The authenticated user must own the order (unless admin)
        if (!$user->isAdmin() && (int) $order->customer_id !== (int) $user->id) {
            return $this->error('You can only create payments for your own orders.', 403);
        }

        $expectedAmount = OrderWalletPaymentService::resolvePayableAmount($order);
        if ($expectedAmount <= 0 || (int) round((float) $data['amount'] * 100) !== (int) round($expectedAmount * 100)) {
            return $this->error('The payment amount does not match the order total.', 422);
        }
        if (strtolower((string) $order->payment_method) !== strtolower($data['method'])) {
            return $this->error('The payment method does not match the order.', 422);
        }
        if (!$user->isAdmin() && isset($data['customer_id'])
            && (int) $data['customer_id'] !== (int) $order->customer_id) {
            return $this->error('Payment customer does not match the order owner.', 422);
        }

        $alreadyPaid = Payment::where('order_id', $data['order_id'])
            ->whereIn('status', ['paid', 'pending'])
            ->exists();

        if ($alreadyPaid) {
            return $this->error('A payment already exists for this order.', 409);
        }

        $payment = Payment::create([
            'order_id'           => $data['order_id'],
            'customer_id'        => $order->customer_id,
            'partner_id'         => $data['partner_id'] ?? null,
            'driver_id'          => $data['driver_id'] ?? null,
            'amount'             => $expectedAmount,
            'currency'           => $data['currency'] ?? 'PHP',
            'method'             => $data['method'],
            'status'             => $data['status'] ?? 'pending',
            'provider'           => $data['provider'] ?? null,
            'provider_reference' => $data['provider_reference'] ?? null,
            'paid_at'            => $data['paid_at'] ?? null,
            'meta'               => $data['meta'] ?? null,
        ]);

        CacheService::forgetByPattern("payments:user:{$data['customer_id']}:list:*");
        CacheService::forgetByPattern("payments:admin:list:*");

        return $this->created($payment, 'Payment recorded successfully');
    }

    /**
     * @OA\Get(
     *     path="/api/v1/payments/{id}",
     *     summary="Get payment by ID",
     *     tags={"Payments"},
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\Response(response=200, description="Payment details",
     *         @OA\JsonContent(@OA\Property(property="data", ref="#/components/schemas/Payment"))
     *     ),
     *     @OA\Response(response=403, ref="#/components/schemas/ErrorResponse")
     * )
     */
    public function show(Request $request, Payment $payment): JsonResponse
    {
        $user = $request->user();

        if (!$user->isAdmin() && (int) $payment->customer_id !== (int) $user->id) {
            return $this->error('Forbidden', 403);
        }

        $cacheKey = "payments:payment:{$payment->id}";

        $payment = CacheService::remember($cacheKey, CacheService::CACHE_SHORT, function () use ($payment) {
            $payment->load([
                'order:id,customer_id,service_id,status,payment_method,estimated_fare,actual_fare',
                'customer:id,name,email,phone_number',
                'partner:id,name,status',
                'driverProfile:id,user_id,status,rating',
            ]);
            return $payment;
        });

        return $this->success($payment);
    }

    /**
     * @OA\Post(
     *     path="/api/v1/webhooks/payments/{provider}",
     *     summary="Receive payment webhook from provider (PayMongo, Xendit, GCash, Maya)",
     *     tags={"Payments"},
     *     @OA\Parameter(name="provider", in="path", required=true, @OA\Schema(type="string", enum={"paymongo","xendit","gcash","maya"})),
     *     @OA\Response(response=200, description="Webhook accepted"),
     *     @OA\Response(response=400, description="Invalid signature")
     * )
     */
    public function webhook(Request $request, string $provider): JsonResponse
    {
        if (!$this->verifyWebhookSignature($request, $provider)) {
            return $this->error('Invalid webhook signature', 400);
        }

        $payload = $this->normalizeWebhookPayload($request->all(), $provider);

        // Process synchronously to avoid queue worker dependency on free-tier hosting
        ProcessPaymentWebhookJob::dispatchSync($provider, $payload);

        return $this->message('Webhook received');
    }

    private function verifyWebhookSignature(Request $request, string $provider): bool
    {
        if ($provider === 'paymongo') {
            $signature = $request->header('X-Paymongo-Signature', '');
            return app(PayMongoService::class)->verifyWebhookSignature(
                $request->getContent(),
                $signature
            );
        }

        if ($provider === 'xendit') {
            $token = $request->header('X-CALLBACK-TOKEN', '');
            return app(PaymentGatewayService::class)->verifyWebhookToken($token);
        }

        $secret = config("services.{$provider}.webhook_secret");

        if (!$secret) {
            // No secret configured = reject unknown providers for security
            Log::warning('Webhook rejected: no secret configured', ['provider' => $provider]);
            return false;
        }

        $signature = $request->header('X-Webhook-Signature', '');
        $expected  = hash_hmac('sha256', $request->getContent(), $secret);

        return hash_equals($expected, $signature);
    }

    /**
     * Normalize webhook payloads across providers into a consistent format
     * for ProcessPaymentWebhookJob.
     */
    private function normalizeWebhookPayload(array $payload, string $provider): array
    {
        if ($provider === 'paymongo') {
            $event = $payload['data'] ?? [];
            $eventType = $event['attributes']['type'] ?? '';
            $eventData = $event['attributes']['data'] ?? [];
            $eventAttrs = $eventData['attributes'] ?? [];

            $reference = $eventData['id'] ?? null;
            $status = $this->paymongoEventStatus($eventType, $eventAttrs);

            // For transfers, external reference is stored in different fields; also capture callback metadata
            $externalId = $eventAttrs['metadata']['external_id']
                ?? $eventAttrs['reference_number']
                ?? $eventAttrs['external_id']
                ?? $eventAttrs['callback_url']
                ?? null;

            // Payments created under a checkout session appear in the session's
            // own payload as well as standalone payment.paid events. Collect the
            // payment ids so payment-only events can be matched back to the fee.
            $paymentIds = [];
            foreach (($eventAttrs['payments'] ?? []) as $payment) {
                $pid = is_array($payment) ? ($payment['id'] ?? null) : $payment;
                if (is_string($pid) && str_starts_with(strtolower($pid), 'pay_')) {
                    $paymentIds[] = $pid;
                }
            }

            return [
                'id'           => $reference,
                'status'       => $status,
                'external_id'  => $externalId,
                'reference'    => $reference, // keep both keys for compatibility
                'provider'     => 'paymongo',
                'event_type'   => $eventType,
                'raw_status'   => $eventAttrs['status'] ?? null,
                'amount'       => isset($eventAttrs['amount']) ? ((float) $eventAttrs['amount'] / 100) : null,
                'currency'     => strtoupper((string) ($eventAttrs['currency'] ?? '')),
                'payment_ids'  => array_values(array_unique($paymentIds)),
            ];
        }

        // Xendit and others pass the payload as-is
        return $payload;
    }

    private function paymongoEventStatus(string $eventType, array $eventAttrs): string
    {
        if (str_contains($eventType, 'payment.paid') || str_contains($eventType, 'payment.succeeded')) {
            return 'PAID';
        }
        if (str_contains($eventType, 'payment.failed')) {
            return 'FAILED';
        }
        if (str_contains($eventType, 'checkout_session.payment.paid')) {
            return 'PAID';
        }
        if (str_contains($eventType, 'checkout_session.completed')) {
            $status = $eventAttrs['status'] ?? '';
            if ($status === 'paid') return 'PAID';
            if ($status === 'failed') return 'FAILED';
        }
        if (str_contains($eventType, 'transfer.succeeded')) {
            return 'SUCCEEDED';
        }
        if (str_contains($eventType, 'transfer.failed')) {
            return 'FAILED';
        }

        return $eventAttrs['status'] ?? 'PENDING';
    }
}
