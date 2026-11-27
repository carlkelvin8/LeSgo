<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Exception\Messaging\NotFound;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\AndroidConfig;
use Kreait\Firebase\Messaging\ApnsConfig;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

class FcmService
{
    /** Android channel created by the app (loud custom alarm) for order alerts. */
    public const ORDER_CHANNEL_ID = 'lezgo_orders';

    /** Notification types that must alarm the user instead of just showing a banner. */
    private const ORDER_ALERT_TYPES = ['new_order_available', 'new_merchant_order', 'order.assigned'];

    public function __construct(private Messaging $messaging) {}

    /**
     * Send a push notification to a single FCM token.
     */
    public function sendToToken(string $token, string $title, string $body, array $data = []): bool
    {
        try {
            $this->messaging->send(
                $this->buildMessage($title, $body, $data)->toToken($token)
            );
            return true;
        } catch (NotFound $e) {
            // Firebase says this token is unregistered (app uninstalled / token rotated).
            $this->forgetTokens([$token]);
            Log::info('FCM token is unregistered; cleared it', ['token' => substr($token, 0, 20) . '...']);
            return false;
        } catch (\Throwable $e) {
            Log::warning('FCM send failed', [
                'token' => substr($token, 0, 20) . '...',
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    /**
     * Send to multiple tokens (multicast).
     */
    public function sendToMultiple(array $tokens, string $title, string $body, array $data = []): array
    {
        if (empty($tokens)) {
            return ['success' => 0, 'failure' => 0];
        }

        try {
            $report = $this->messaging->sendMulticast(
                $this->buildMessage($title, $body, $data),
                $tokens
            );

            $this->forgetTokens(array_merge($report->unknownTokens(), $report->invalidTokens()));

            return [
                'success' => $report->successes()->count(),
                'failure' => $report->failures()->count(),
            ];
        } catch (\Throwable $e) {
            Log::warning('FCM multicast failed', ['error' => $e->getMessage()]);
            return ['success' => 0, 'failure' => count($tokens)];
        }
    }

    /** Stop pushing to tokens Firebase will never deliver to again. */
    private function forgetTokens(array $tokens): void
    {
        if ($tokens !== []) {
            User::whereIn('fcm_token', $tokens)->update(['fcm_token' => null]);
        }
    }

    /**
     * Notification + data message that makes a sound and is delivered immediately.
     * iOS plays no sound unless aps.sound is set; Android needs high priority to
     * wake a sleeping device and an explicit sound on the notification.
     */
    private function buildMessage(string $title, string $body, array $data): CloudMessage
    {
        $isOrderAlert = in_array((string) ($data['type'] ?? ''), self::ORDER_ALERT_TYPES, true);

        return CloudMessage::new()
            ->withNotification(Notification::create($title, $body))
            ->withData(array_map(
                fn ($value) => is_scalar($value) || $value === null ? (string) $value : json_encode($value),
                $data
            ))
            ->withAndroidConfig(AndroidConfig::fromArray([
                'priority' => 'high',
                // Android 8+ uses the channel's sound; installs without the channel fall back to default.
                'notification' => $isOrderAlert
                    ? ['sound' => 'order_bell', 'channel_id' => self::ORDER_CHANNEL_ID]
                    : ['sound' => 'default'],
            ]))
            ->withApnsConfig(ApnsConfig::fromArray([
                'headers' => ['apns-priority' => '10'],
                'payload' => ['aps' => ['sound' => 'default']],
            ]));
    }
}
