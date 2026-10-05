<?php

namespace App\Services;

/**
 * Routes payment operations to a configured provider.
 *
 * A provider is selected before a money-moving request starts. We never retry
 * an ambiguous write against a different provider because a timeout can occur
 * after the first provider has already accepted the transaction.
 */
class PaymentGatewayManager
{
    private PayMongoService $paymongo;

    private PaymentGatewayService $xendit;

    public function __construct(PayMongoService $paymongo, PaymentGatewayService $xendit)
    {
        $this->paymongo = $paymongo;
        $this->xendit = $xendit;
    }

    /**
     * Determine which provider to use for a given operation.
     */
    public function resolveProvider(?string $requestedProvider = null): string
    {
        $requestedProvider = $requestedProvider !== null
            ? strtolower(trim($requestedProvider))
            : null;

        if ($requestedProvider !== null) {
            if (! in_array($requestedProvider, ['paymongo', 'xendit'], true)) {
                throw new \InvalidArgumentException('Unsupported payment gateway.');
            }

            $this->ensureProviderConfigured($requestedProvider);

            return $requestedProvider;
        }

        $default = strtolower((string) config('lespay.default_gateway', 'paymongo'));
        $candidates = array_unique([$default, 'paymongo', 'xendit']);

        foreach ($candidates as $candidate) {
            if (in_array($candidate, ['paymongo', 'xendit'], true)
                && $this->providerConfigured($candidate)) {
                return $candidate;
            }
        }

        throw new \RuntimeException('No payment gateway is configured on the server.');
    }

    // -------------------------------------------------------------------------
    // Invoice / Checkout Session (for top-ups and order payments)
    // -------------------------------------------------------------------------

    public function createInvoice(
        float $amount,
        string $externalId,
        string $description,
        array $meta = [],
        ?string $preferredProvider = null,
    ): array {
        $provider = $this->resolveProvider($preferredProvider);

        if ($provider === 'paymongo') {
            return $this->createViaPayMongo($amount, $externalId, $description, $meta);
        }

        return $this->createViaXendit($amount, $externalId, $description, $meta);
    }

    private function createViaPayMongo(
        float $amount,
        string $externalId,
        string $description,
        array $meta,
    ): array {
        $session = $this->paymongo->createCheckoutSession($amount, $externalId, $description, $meta);

        return [
            'id' => $session['id'],
            'external_id' => $externalId,
            'invoice_url' => $session['checkout_url'],
            'status' => $session['status'],
            'amount' => $session['amount'],
            'currency' => $session['currency'],
            'provider' => 'paymongo',
        ];
    }

    private function createViaXendit(
        float $amount,
        string $externalId,
        string $description,
        array $meta,
    ): array {
        $invoice = $this->xendit->createInvoice($amount, $externalId, $description, $meta);

        return [
            'id' => $invoice['id'],
            'external_id' => $invoice['external_id'] ?? $externalId,
            'invoice_url' => $invoice['invoice_url'],
            'status' => $invoice['status'],
            'amount' => $invoice['amount'],
            'currency' => $invoice['currency'],
            'provider' => 'xendit',
        ];
    }

    /**
     * Get invoice/checkout status by provider.
     */
    public function getInvoice(string $reference, string $provider): array
    {
        $provider = strtolower($provider);
        $this->ensureProviderConfigured($provider);

        if ($provider === 'paymongo') {
            return $this->paymongo->getCheckoutSession($reference);
        }

        return $this->xendit->getInvoice($reference);
    }

    // -------------------------------------------------------------------------
    // Refunds
    // -------------------------------------------------------------------------

    public function createRefund(
        string $paymentReference,
        float $amount,
        string $reason = 'REQUESTED_BY_CUSTOMER',
        ?string $provider = null,
        ?string $idempotencyKey = null,
    ): array {
        $provider = $this->resolveProvider($provider);

        if ($provider === 'paymongo') {
            return $this->paymongo->createRefund(
                $paymentReference,
                $amount,
                $this->normalizeRefundReason($reason),
                $idempotencyKey,
            );
        }

        return $this->xendit->createRefund($paymentReference, $amount, $reason, $idempotencyKey);
    }

    // -------------------------------------------------------------------------
    // Payouts / Withdrawals
    // -------------------------------------------------------------------------

    public function createPayout(
        float $amount,
        string $referenceId,
        string $channelCode,
        string $accountHolderName,
        string $accountNumber,
        ?string $description = null,
        ?string $preferredProvider = null,
    ): array {
        $provider = $this->resolvePayoutProvider($preferredProvider);

        if ($provider === 'paymongo') {
            return $this->payoutViaPayMongo(
                $amount,
                $referenceId,
                $channelCode,
                $accountHolderName,
                $accountNumber,
                $description,
            );
        }

        return $this->payoutViaXendit($amount, $referenceId, $channelCode, $accountHolderName, $accountNumber, $description);
    }

    private function payoutViaPayMongo(
        float $amount,
        string $referenceId,
        string $channelCode,
        string $accountHolderName,
        string $accountNumber,
        ?string $description,
    ): array {
        $bic = $this->payMongoBic($channelCode);

        return $this->paymongo->createTransfer(
            $amount,
            $referenceId,
            $bic,
            $accountHolderName,
            $accountNumber,
            $description ?? 'LesGo wallet withdrawal',
            config('services.paymongo.webhook_url'),
        );
    }

    private function payoutViaXendit(
        float $amount,
        string $referenceId,
        string $channelCode,
        string $accountHolderName,
        string $accountNumber,
        ?string $description,
    ): array {
        return $this->xendit->createPayout(
            $amount,
            $referenceId,
            $channelCode,
            $accountHolderName,
            $accountNumber,
            $description,
        );
    }

    /**
     * Map Xendit-style channel codes to PayMongo BIC codes.
     */
    private function payMongoBic(string $channelCode): string
    {
        return match ($channelCode) {
            'PH_GCASH' => (string) config('services.paymongo.gcash_bic', 'GXCHPHM2XXX'),
            'PH_MAYA' => (string) config('services.paymongo.maya_bic', 'PAPHPHM1XXX'),
            default => $channelCode,
        };
    }

    // -------------------------------------------------------------------------
    // Webhook verification
    // -------------------------------------------------------------------------

    public function verifyWebhookToken(string $token, string $provider): bool
    {
        if ($provider === 'paymongo') {
            return false; // PayMongo requires payload-signature verification.
        }

        return $this->xendit->verifyWebhookToken($token);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private function normalizeRefundReason(string $reason): string
    {
        return match (strtoupper($reason)) {
            'DUPLICATE' => 'duplicate',
            'FRAUDULENT' => 'fraudulent',
            'REQUESTED_BY_CUSTOMER' => 'others',
            default => 'others',
        };
    }

    public function normalizeInvoiceStatus(array $invoice, string $provider): string
    {
        $provider = strtolower($provider);
        $rawStatus = $provider === 'paymongo'
            ? ($invoice['payment_status'] ?? $invoice['status'] ?? '')
            : ($invoice['status'] ?? '');

        return match (strtoupper((string) $rawStatus)) {
            'PAID', 'SETTLED', 'SUCCEEDED', 'COMPLETED', 'SUCCESS' => 'paid',
            'FAILED', 'FAILURE', 'DECLINED', 'EXPIRED', 'CANCELLED', 'REJECTED' => 'failed',
            'REFUNDED', 'REVERSED' => 'refunded',
            default => 'pending',
        };
    }

    public function normalizePayoutStatus(array $payout): string
    {
        return match (strtoupper((string) ($payout['status'] ?? ''))) {
            'SUCCEEDED', 'COMPLETED', 'PAID' => 'succeeded',
            'FAILED', 'FAILURE', 'REJECTED', 'EXPIRED', 'CANCELLED', 'REVERSED' => 'failed',
            default => 'pending',
        };
    }

    public function resolvePayoutProvider(?string $requestedProvider = null): string
    {
        $requestedProvider = $requestedProvider !== null
            ? strtolower(trim($requestedProvider))
            : null;
        $candidates = $requestedProvider !== null
            ? [$requestedProvider]
            : array_unique([
                strtolower((string) config('lespay.default_gateway', 'paymongo')),
                'paymongo',
                'xendit',
            ]);

        foreach ($candidates as $candidate) {
            if ($candidate === 'paymongo' && PayMongoService::payoutConfigured()) {
                return 'paymongo';
            }
            if ($candidate === 'xendit' && PaymentGatewayService::configured()) {
                return 'xendit';
            }
        }

        if ($requestedProvider !== null
            && ! in_array($requestedProvider, ['paymongo', 'xendit'], true)) {
            throw new \InvalidArgumentException('Unsupported payment gateway.');
        }

        throw new \RuntimeException('No payout gateway is fully configured on the server.');
    }

    private function ensureProviderConfigured(string $provider): void
    {
        if (! in_array($provider, ['paymongo', 'xendit'], true)) {
            throw new \InvalidArgumentException('Unsupported payment gateway.');
        }

        if (! $this->providerConfigured($provider)) {
            throw new \RuntimeException(ucfirst($provider).' is not configured on the server.');
        }
    }

    private function providerConfigured(string $provider): bool
    {
        return match ($provider) {
            'paymongo' => PayMongoService::configured(),
            'xendit' => PaymentGatewayService::configured(),
            default => false,
        };
    }
}
