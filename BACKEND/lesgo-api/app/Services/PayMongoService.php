<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class PayMongoService
{
    private const BASE_URL = 'https://api.paymongo.com/v1';
    private const BASE_URL_V2 = 'https://api.paymongo.com/v2';

    public static function secretKey(): string
    {
        return config('services.paymongo.secret_key') ?: '';
    }

    public static function configured(): bool
    {
        return self::secretKey() !== '';
    }

    public static function payoutConfigured(): bool
    {
        return self::configured()
            && trim((string) config('services.paymongo.wallet_account_number', '')) !== '';
    }

    private function authHeaders(): array
    {
        return [
            'Authorization' => 'Basic ' . base64_encode(self::secretKey() . ':'),
            'Content-Type'  => 'application/json',
            'Accept'        => 'application/json',
        ];
    }

    // -------------------------------------------------------------------------
    // Checkout Sessions (hosted checkout — supports GCash, Maya, cards, etc.)
    // -------------------------------------------------------------------------

    public function createCheckoutSession(
        float $amount,
        string $externalId,
        string $description,
        array $meta = [],
    ): array {
        $centavos = (int) round($amount * 100);

        $payload = [
            'data' => [
                'attributes' => [
                    'reference_number' => $externalId,
                    'send_email_receipt' => false,
                    'show_description'   => true,
                    'show_line_items'    => true,
                    'line_items' => [
                        [
                            'name'        => $description,
                            'amount'      => $centavos,
                            'currency'    => $meta['currency'] ?? 'PHP',
                            'quantity'    => 1,
                            'description' => $description,
                        ],
                    ],
                    'payment_method_types' => $this->paymentMethodTypes($meta['payment_method'] ?? null),
                    'success_url' => $meta['success_redirect_url'] ?? config('services.paymongo.success_url'),
                    'cancel_url'  => $meta['failure_redirect_url'] ?? config('services.paymongo.failure_url'),
                    'metadata' => array_merge(
                        ['external_id' => $externalId],
                        $meta['metadata'] ?? [],
                    ),
                ],
            ],
        ];

        if (!empty($meta['customer_email']) || !empty($meta['customer_name'])) {
            $payload['data']['attributes']['customer_email'] = $meta['customer_email'] ?? null;
        }

        $response = Http::timeout(15)
            ->withHeaders($this->authHeaders())
            ->withHeaders(['Idempotency-Key' => $externalId])
            ->post(self::BASE_URL . '/checkout_sessions', $payload);

        if (!$response->successful()) {
            $body = $response->json();
            $errors = $body['errors'] ?? [];
            $message = collect($errors)->pluck('detail')->first()
                ?? ($body['message'] ?? $response->body());
            throw new \RuntimeException(
                'PayMongo checkout session request failed (' . $response->status() . '): ' . $message
            );
        }

        $data = $response->json()['data'] ?? [];
        $attrs = $data['attributes'] ?? [];

        return [
            'id'           => $data['id'] ?? null,
            'status'       => $attrs['status'] ?? 'pending',
            'checkout_url' => $attrs['checkout_url'] ?? null,
            'amount'       => $amount,
            'currency'     => $attrs['currency'] ?? 'PHP',
            'created_at'   => $attrs['created_at'] ?? null,
        ];
    }

    public function getPayment(string $paymentId): array
    {
        $response = Http::timeout(15)
            ->withHeaders($this->authHeaders())
            ->get(self::BASE_URL . '/payments/' . $paymentId);

        if (!$response->successful()) {
            $body = $response->json();
            $message = $body['errors'][0]['detail'] ?? $body['message'] ?? $response->body();
            throw new \RuntimeException(
                'PayMongo get payment failed (' . $response->status() . '): ' . $message
            );
        }

        $data = $response->json()['data'] ?? [];
        $attrs = $data['attributes'] ?? [];

        return [
            'id'             => $data['id'] ?? null,
            'status'         => $attrs['status'] ?? 'pending',
            'amount'         => ($attrs['amount'] ?? 0) / 100,
            'currency'       => $attrs['currency'] ?? 'PHP',
            'metadata'       => $attrs['metadata'] ?? [],
            'payment_intent' => $attrs['payment_intent'] ?? null,
            'created_at'     => $attrs['created_at'] ?? null,
        ];
    }

    public function getCheckoutSession(string $sessionId): array
    {
        $response = Http::timeout(15)
            ->withHeaders($this->authHeaders())
            ->get(self::BASE_URL . '/checkout_sessions/' . $sessionId);

        if (!$response->successful()) {
            $body = $response->json();
            $message = $body['errors'][0]['detail'] ?? $body['message'] ?? $response->body();
            throw new \RuntimeException(
                'PayMongo get checkout session failed (' . $response->status() . '): ' . $message
            );
        }

        $data = $response->json()['data'] ?? [];
        $attrs = $data['attributes'] ?? [];

        $payments = $attrs['payments'] ?? [];

        return [
            'id'             => $data['id'] ?? null,
            'status'         => $attrs['status'] ?? 'pending',
            'checkout_url'   => $attrs['checkout_url'] ?? null,
            'amount'         => collect($attrs['line_items']['data'] ?? $attrs['line_items'] ?? [])->sum(fn ($item) => ($item['amount'] ?? 0) * ($item['quantity'] ?? 1)) / 100,
            'currency'       => $attrs['currency'] ?? 'PHP',
            'payments'       => $payments,
            'payment_status' => $this->resolvePaymentStatus($payments, $attrs['status'] ?? 'active'),
        ];
    }

    // -------------------------------------------------------------------------
    // Payment Links (alternative to checkout sessions)
    // -------------------------------------------------------------------------

    public function createPaymentLink(
        float $amount,
        string $description,
        array $meta = [],
    ): array {
        $centavos = (int) round($amount * 100);

        $payload = [
            'amount'      => $centavos,
            'currency'    => $meta['currency'] ?? 'PHP',
            'description' => $description,
            'metadata'    => $meta['metadata'] ?? [],
        ];

        $response = Http::timeout(15)
            ->withHeaders($this->authHeaders())
            ->post(self::BASE_URL . '/payment_links', $payload);

        if (!$response->successful()) {
            $body = $response->json();
            $message = $body['errors'][0]['detail'] ?? $body['message'] ?? $response->body();
            throw new \RuntimeException(
                'PayMongo create payment link failed (' . $response->status() . '): ' . $message
            );
        }

        $data = $response->json()['data'] ?? [];

        return [
            'id'         => $data['id'] ?? null,
            'url'        => $data['url'] ?? null,
            'status'     => $data['status'] ?? 'active',
            'amount'     => $amount,
            'currency'   => $data['currency'] ?? 'PHP',
            'created_at' => $data['created_at'] ?? null,
        ];
    }

    // -------------------------------------------------------------------------
    // Refunds
    // -------------------------------------------------------------------------

    public function createRefund(string $paymentId, float $amount, string $reason = 'others'): array
    {
        $centavos = (int) round($amount * 100);

        $validReasons = ['duplicate', 'fraudulent', 'others'];
        if (!in_array($reason, $validReasons, true)) {
            $reason = 'others';
        }

        $payload = [
            'data' => [
                'attributes' => [
                    'amount'     => $centavos,
                    'payment_id' => $paymentId,
                    'reason'     => $reason,
                ],
            ],
        ];

        $response = Http::timeout(15)
            ->withHeaders($this->authHeaders())
            ->post(self::BASE_URL . '/refunds', $payload);

        if (!$response->successful()) {
            $body = $response->json();
            $message = $body['errors'][0]['detail'] ?? $body['message'] ?? $response->body();
            throw new \RuntimeException(
                'PayMongo refund failed (' . $response->status() . '): ' . $message
            );
        }

        $data = $response->json()['data'] ?? [];
        $attrs = $data['attributes'] ?? [];

        return [
            'id'         => $data['id'] ?? null,
            'amount'     => ($attrs['amount'] ?? 0) / 100,
            'status'     => $attrs['status'] ?? 'pending',
            'reason'     => $attrs['reason'] ?? $reason,
            'created_at' => $attrs['created_at'] ?? null,
        ];
    }

    // -------------------------------------------------------------------------
    // Transfers (withdrawals / payouts to GCash, Maya, bank)
    // -------------------------------------------------------------------------

    public function getReceivingInstitutions(string $provider = 'instapay'): array
    {
        $response = Http::timeout(15)
            ->withHeaders($this->authHeaders())
            ->get(self::BASE_URL . '/wallets/receiving_institutions', [
                'provider' => $provider,
            ]);

        if (!$response->successful()) {
            return [];
        }

        return $response->json()['data'] ?? [];
    }

    public function createTransfer(
        float $amount,
        string $referenceId,
        string $recipientBic,
        string $recipientName,
        string $recipientNumber,
        ?string $description = null,
        ?string $callbackUrl = null,
    ): array {
        $centavos = (int) round($amount * 100);

        $walletNumber = config('services.paymongo.wallet_account_number', '');
        $walletName = config('services.paymongo.wallet_account_name', 'LeSGo Platform');

        $payload = [
            'transfers' => [
                [
                    'source_account' => [
                        'number' => $walletNumber,
                        'name'   => $walletName,
                        'bic'    => 'PAEYPHM2XXX',
                    ],
                    'destination_account' => [
                        'number' => $recipientNumber,
                        'name'   => $recipientName,
                        'bic'    => $recipientBic,
                    ],
                    'amount'     => $centavos,
                    'currency'   => 'PHP',
                    'provider'   => 'instapay',
                    'description' => $description ?? 'LesGo wallet withdrawal',
                    'callback_url' => $callbackUrl,
                    'reference_number' => $referenceId,
                ],
            ],
        ];

        $response = Http::timeout(30)
            ->withHeaders($this->authHeaders())
            ->withHeaders(['Idempotency-Key' => $referenceId])
            ->post(self::BASE_URL_V2 . '/batch_transfers', $payload);

        if (!$response->successful()) {
            $body = $response->json();
            $message = $body['errors'][0]['detail'] ?? $body['message'] ?? $response->body();
            throw new \RuntimeException(
                'PayMongo transfer failed (' . $response->status() . '): ' . $message
            );
        }

        $body = $response->json() ?? [];
        $transfers = $body['data']['transfers'] ?? $body['transfers'] ?? [];
        $transfer = $transfers[0] ?? [];

        return [
            'id'           => $transfer['id'] ?? null,
            'status'       => $transfer['status'] ?? 'pending',
            'amount'       => $amount,
            'currency'     => 'PHP',
            'created_at'   => $transfer['created_at'] ?? null,
        ];
    }

    public function getTransfer(string $transferId): array
    {
        $response = Http::timeout(15)
            ->withHeaders($this->authHeaders())
            ->get(self::BASE_URL_V2 . '/transfers/' . $transferId);

        if (!$response->successful()) {
            $body = $response->json();
            $message = $body['errors'][0]['detail'] ?? $body['message'] ?? $response->body();
            throw new \RuntimeException(
                'PayMongo get transfer failed (' . $response->status() . '): ' . $message
            );
        }

        $data = $response->json() ?? [];

        return [
            'id'         => $data['id'] ?? null,
            'status'     => $data['status'] ?? 'pending',
            'amount'     => ($data['amount'] ?? 0) / 100,
            'currency'   => $data['currency'] ?? 'PHP',
            'created_at' => $data['created_at'] ?? null,
        ];
    }

    // -------------------------------------------------------------------------
    // Webhook verification
    // -------------------------------------------------------------------------

    public function verifyWebhookSignature(string $payload, string $signatureHeader): bool
    {
        $secret = config('services.paymongo.webhook_secret', '');

        if (empty($secret)) {
            Log::warning('PayMongo webhook secret not configured — rejecting webhook');
            return false;
        }

        // PayMongo sends: t=<timestamp>,v1=<sig>,te=<test_sig>,li=<live_sig> (or subset)
        // Support all variants per PayMongo docs: https://developers.paymongo.com/docs/webhooks
        $parts = [];
        foreach (explode(',', $signatureHeader) as $pair) {
            [$key, $value] = array_pad(explode('=', $pair, 2), 2, '');
            $parts[trim($key)] = trim($value);
        }

        $timestamp = $parts['t'] ?? '';
        // Prefer v1, fallback to te (test) / li (live) for compatibility
        $signature = $parts['v1'] ?? $parts['te'] ?? $parts['li'] ?? '';

        if (empty($timestamp) || empty($signature)) {
            return false;
        }

        // Replay protection: timestamp must be within 5 minutes (PayMongo recommends 300s)
        if (!ctype_digit($timestamp)) {
            return false;
        }
        $tolerance = 300;
        $now = time();
        $ts = (int) $timestamp;
        if (abs($now - $ts) > $tolerance) {
            Log::warning('PayMongo webhook timestamp outside tolerance', ['timestamp' => $timestamp, 'now' => $now]);
            return false;
        }

        $signedPayload = $timestamp . '.' . $payload;
        $expected = hash_hmac('sha256', $signedPayload, $secret);

        return hash_equals($expected, $signature);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private function paymentMethodTypes(?string $method): array
    {
        return match (strtolower(trim((string) $method))) {
            'gcash' => ['gcash'],
            'maya', 'paymaya' => ['paymaya'],
            'card', 'cards' => ['card'],
            'qrph', 'qr_ph' => ['qrph'],
            default => ['gcash', 'paymaya', 'card', 'qrph'],
        };
    }

    private function resolvePaymentStatus(array $payments, string $sessionStatus = 'active'): string
    {
        // A failed attempt does not terminate an active hosted checkout. A later
        // successful attempt takes precedence regardless of array ordering.
        foreach ($payments as $payment) {
            $status = strtolower($payment['attributes']['status'] ?? $payment['status'] ?? '');
            if (in_array($status, ['paid', 'succeeded'], true)) {
                return 'paid';
            }
        }
        return in_array(strtolower($sessionStatus), ['expired', 'cancelled', 'failed'], true)
            ? strtolower($sessionStatus) : 'pending';
    }
}
