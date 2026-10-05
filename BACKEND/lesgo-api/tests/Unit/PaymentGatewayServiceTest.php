<?php

namespace Tests\Unit;

use App\Services\PaymentGatewayService;
use Tests\TestCase;

/**
 * Service-level tests using the normal application lifecycle so Laravel's
 * global error and exception handlers are restored after every test.
 */
class PaymentGatewayServiceTest extends TestCase
{
    public function test_webhook_token_fails_closed_when_not_configured(): void
    {
        config(['services.xendit.webhook_token' => '']);
        config(['services.xendit.secret_key' => '']);

        $service = new PaymentGatewayService;
        $this->assertFalse($service->verifyWebhookToken('anything'));
    }

    public function test_webhook_token_passes_with_correct_token(): void
    {
        config(['services.xendit.webhook_token' => 'my-secret-token']);
        config(['services.xendit.secret_key' => '']);

        $service = new PaymentGatewayService;
        $this->assertTrue($service->verifyWebhookToken('my-secret-token'));
    }

    public function test_webhook_token_fails_with_wrong_token(): void
    {
        config(['services.xendit.webhook_token' => 'my-secret-token']);
        config(['services.xendit.secret_key' => '']);

        $service = new PaymentGatewayService;
        $this->assertFalse($service->verifyWebhookToken('wrong-token'));
    }
}
