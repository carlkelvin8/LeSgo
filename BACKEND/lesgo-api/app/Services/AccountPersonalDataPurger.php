<?php

namespace App\Services;

use App\Models\ChatConversation;
use App\Models\DocumentVerification;
use App\Models\GdprRequest;
use App\Models\Order;
use App\Models\OrderTrackingEvent;
use App\Models\Payment;
use App\Models\RatingReview;
use App\Models\SupportTicket;
use App\Models\SupportTicketMessage;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AccountPersonalDataPurger
{
    /**
     * Collect object keys before database rows are erased. No external side
     * effects occur here; deletion is queued only after the transaction commits.
     *
     * @return list<string>
     */
    public function collectMediaPaths(User $user, bool $includeVerificationDocuments = true): array
    {
        $paths = [
            $user->getRawOriginal('profile_photo_url'),
            $user->getRawOriginal('profile_picture'),
        ];

        $driverProfile = $user->driverProfile;
        if ($driverProfile) {
            $this->appendPaths($paths, $driverProfile->getRawOriginal('id_document_path'));
            $this->appendPaths($paths, $driverProfile->documents);
        }

        if (Schema::hasTable('driver_duty_attendances')) {
            $this->appendPaths(
                $paths,
                DB::table('driver_duty_attendances')
                    ->where('user_id', $user->id)
                    ->pluck('photo_path')
                    ->all()
            );
        }

        if ($includeVerificationDocuments) {
            DocumentVerification::query()
                ->where('user_id', $user->id)
                ->each(fn (DocumentVerification $document) => $this->appendPaths($paths, $document->document_urls));
        }

        RatingReview::query()
            ->where(function ($query) use ($user) {
                $query->where('user_id', $user->id)
                    ->orWhere('driver_id', $user->id);
            })
            ->each(fn (RatingReview $review) => $this->appendPaths($paths, $review->review_images));

        SupportTicket::query()
            ->where('user_id', $user->id)
            ->with('messages:id,ticket_id,attachments')
            ->each(function (SupportTicket $ticket) use (&$paths) {
                $this->appendPaths($paths, $ticket->attachments);
                foreach ($ticket->messages as $message) {
                    $this->appendPaths($paths, $message->attachments);
                }
            });

        SupportTicketMessage::query()
            ->where('user_id', $user->id)
            ->each(fn (SupportTicketMessage $message) => $this->appendPaths($paths, $message->attachments));

        $conversationIds = ChatConversation::query()
            ->forUser($user->id)
            ->pluck('id');
        if ($conversationIds->isNotEmpty()) {
            DB::table('chat_messages')
                ->whereIn('conversation_id', $conversationIds)
                ->pluck('attachments')
                ->each(function ($attachments) use (&$paths) {
                    $decoded = is_string($attachments) ? json_decode($attachments, true) : $attachments;
                    $this->appendPaths($paths, $decoded);
                });
        }

        if ($user->isCustomer()) {
            Order::query()
                ->where('customer_id', $user->id)
                ->with('trackingEvents:id,order_id,attachments')
                ->each(function (Order $order) use (&$paths) {
                    $this->appendPaths($paths, $order->proof_images);
                    foreach ($order->trackingEvents as $event) {
                        $this->appendPaths($paths, $event->attachments);
                    }
                });
        }

        GdprRequest::query()
            ->where('user_id', $user->id)
            ->pluck('export_file_path')
            ->each(fn ($path) => $this->appendPaths($paths, $path));

        return array_values(array_unique(array_filter(
            $paths,
            fn ($path) => is_string($path) && trim($path) !== ''
        )));
    }

    public function purgeCustomer(User $user): void
    {
        $this->redactCustomerOrders($user);
        $this->purgeCommonData($user);
        $user->customerProfile()->delete();
        $user->addresses()->delete();
    }

    public function purgeDriver(User $user): void
    {
        $this->redactDriverActivity($user);
        $this->purgeCommonData($user);

        $profile = $user->driverProfile;
        if (! $profile) {
            return;
        }

        $profile->vehicles()->delete();
        $profile->forceFill([
            'partner_id' => null,
            'status' => 'deleted',
            'is_available' => false,
            'license_number' => null,
            'license_expiry_date' => null,
            'id_document_path' => null,
            'documents' => null,
            'last_latitude' => null,
            'last_longitude' => null,
            'vehicle_type' => null,
            'plate_number' => null,
        ])->saveQuietly();
    }

    private function redactCustomerOrders(User $user): void
    {
        Order::query()
            ->where('customer_id', $user->id)
            ->chunkById(100, function ($orders) use ($user) {
                $orderIds = $orders->pluck('id');

                foreach ($orders as $order) {
                    $order->forceFill([
                        'pickup_address_id' => null,
                        'dropoff_address_id' => null,
                        'pickup_address' => null,
                        'pickup_lat' => null,
                        'pickup_lng' => null,
                        'pickup_contact_name' => null,
                        'pickup_contact_phone' => null,
                        'dropoff_address' => null,
                        'dropoff_lat' => null,
                        'dropoff_lng' => null,
                        'dropoff_contact_name' => null,
                        'dropoff_contact_phone' => null,
                        'notes' => null,
                        'item_description' => null,
                        'passenger_name' => null,
                        'proof_images' => null,
                        'proof_uploaded_at' => null,
                        'meta' => $this->removeSensitiveMetadata($order->meta),
                    ])->saveQuietly();
                }

                DB::table('lesbuy_items')
                    ->whereIn('order_id', $orderIds)
                    ->update(['notes' => null]);

                OrderTrackingEvent::query()
                    ->whereIn('order_id', $orderIds)
                    ->update([
                        'event_description' => null,
                        'latitude' => null,
                        'longitude' => null,
                        'location_address' => null,
                        'metadata' => null,
                        'attachments' => null,
                    ]);

                OrderTrackingEvent::query()
                    ->whereIn('order_id', $orderIds)
                    ->where('user_id', $user->id)
                    ->update(['user_id' => null]);

                Payment::query()
                    ->whereIn('order_id', $orderIds)
                    ->each(function (Payment $payment) {
                        $payment->meta = $this->removeSensitiveMetadata($payment->meta);
                        $payment->saveQuietly();
                    });
            });
    }

    private function redactDriverActivity(User $user): void
    {
        $driverProfileId = $user->driverProfile?->id;
        if ($driverProfileId !== null) {
            Payment::query()
                ->where('driver_id', $driverProfileId)
                ->each(function (Payment $payment) {
                    $payment->meta = $this->removeSensitiveMetadata($payment->meta);
                    $payment->saveQuietly();
                });
        }

        DB::table('order_tracking_events')
            ->where('user_id', $user->id)
            ->update([
                'user_id' => null,
                'event_description' => null,
                'latitude' => null,
                'longitude' => null,
                'location_address' => null,
                'metadata' => null,
                'attachments' => null,
            ]);

        if (Schema::hasTable('driver_duty_attendances')) {
            DB::table('driver_duty_attendances')
                ->where('user_id', $user->id)
                ->delete();
        }

        $user->driverLocations()->delete();
    }

    /**
     * Merchant owners and staff: purge the person's own data but keep their
     * verification documents (business permits, IDs) when an account is
     * deleted. Business policy is to keep those documents through this flow.
     */
    public function purgeMerchantUser(User $user): void
    {
        $this->purgeCommonData($user, retainVerificationDocuments: true);
        $user->addresses()->delete();
    }

    private function purgeCommonData(User $user, bool $retainVerificationDocuments = false): void
    {
        $conversationIds = ChatConversation::query()
            ->forUser($user->id)
            ->pluck('id');
        if ($conversationIds->isNotEmpty()) {
            ChatConversation::query()->whereIn('id', $conversationIds)->delete();
        }

        SupportTicketMessage::query()->where('user_id', $user->id)->delete();
        $user->supportTickets()->delete();

        RatingReview::query()
            ->where(function ($query) use ($user) {
                $query->where('user_id', $user->id)
                    ->orWhere('driver_id', $user->id);
            })
            ->delete();

        if (! $retainVerificationDocuments) {
            $user->documentVerifications()->delete();
        }
        $user->socialShares()->delete();
        $user->userSessions()->delete();
        $user->geofenceEvents()->delete();
        $user->websocketConnections()->delete();
        $user->realtimeNotifications()->delete();
        $user->refreshTokens()->delete();

        $this->deleteRowsByUserId([
            'notifications',
            'two_factor_auth',
            'biometric_auth',
            'wallet_linked_accounts',
            'customer_missions',
            'customer_satisfaction_surveys',
            'analytics_events',
        ], $user->id);

        if (Schema::hasTable('customer_behavior_metrics')) {
            DB::table('customer_behavior_metrics')
                ->where('customer_id', $user->id)
                ->delete();
        }

        if (Schema::hasTable('driver_performance_metrics')) {
            DB::table('driver_performance_metrics')
                ->where('driver_id', $user->id)
                ->delete();
        }

        GdprRequest::query()
            ->where('user_id', $user->id)
            ->update([
                'description' => null,
                'requested_data' => null,
                'verification_token' => null,
                'processing_notes' => null,
                'export_file_path' => null,
                'export_expires_at' => null,
                'metadata' => null,
            ]);
    }

    /** @param list<string> $tables */
    private function deleteRowsByUserId(array $tables, int $userId): void
    {
        foreach ($tables as $table) {
            if (Schema::hasTable($table) && Schema::hasColumn($table, 'user_id')) {
                DB::table($table)->where('user_id', $userId)->delete();
            }
        }
    }

    private function removeSensitiveMetadata(mixed $value): mixed
    {
        if (! is_array($value)) {
            return null;
        }

        $sanitized = [];
        foreach ($value as $key => $item) {
            if (is_string($key) && preg_match(
                '/address|location|latitude|longitude|(^|_)lat$|(^|_)lng$|phone|email|name|contact|note|instruction|photo|image|attachment/i',
                $key
            )) {
                continue;
            }

            $sanitized[$key] = is_array($item)
                ? $this->removeSensitiveMetadata($item)
                : $item;
        }

        return $sanitized ?: null;
    }

    /** @param array<int, mixed> $paths */
    private function appendPaths(array &$paths, mixed $value): void
    {
        if (is_string($value)) {
            if (trim($value) !== '') {
                $paths[] = $value;
            }

            return;
        }

        if (! is_array($value)) {
            return;
        }

        foreach ($value as $item) {
            $this->appendPaths($paths, $item);
        }
    }
}
