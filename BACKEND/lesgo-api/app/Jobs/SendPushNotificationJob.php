<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\FcmService;
use App\Services\SmsService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendPushNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;

    public int $backoff = 30;

    public function __construct(
        private int $userId,
        private string $title,
        private string $body,
        private array $data = [],
        private bool $smsFallback = false
    ) {
        $this->onQueue('notifications');
    }

    public function handle(): void
    {
        $user = User::find($this->userId);

        if (! $user) {
            Log::warning('SendPushNotificationJob: user not found', ['user_id' => $this->userId]);

            return;
        }

        $sent = false;

        if ($user->fcm_token) {
            try {
                $sent = app(FcmService::class)->sendToToken(
                    $user->fcm_token,
                    $this->title,
                    $this->body,
                    $this->data
                );
            } catch (\Throwable $e) {
                Log::warning('Push provider is unavailable', [
                    'user_id' => $this->userId,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        // SMS fallback: send if push failed or no FCM token and user has phone
        if (! $sent && $this->smsFallback && $user->phone_number) {
            app(SmsService::class)->send(
                $user->phone_number,
                "{$this->title}: {$this->body}"
            );
        }
    }

    public function failed(\Throwable $e): void
    {
        Log::error('SendPushNotificationJob failed', [
            'user_id' => $this->userId,
            'title' => $this->title,
            'error' => $e->getMessage(),
        ]);
    }
}
