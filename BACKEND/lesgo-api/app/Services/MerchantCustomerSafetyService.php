<?php

namespace App\Services;

use App\Models\ChatReport;
use App\Models\Order;
use App\Models\Partner;
use App\Models\SupportTicket;
use App\Models\User;
use App\Models\UserBlock;
use Illuminate\Support\Facades\DB;

/**
 * Lets a store report an abusive customer and stop taking their orders.
 *
 * Merchants have no chat with customers, so a report hangs off an order and
 * reuses the chat report and block tables (conversation_id is nullable there).
 * The store *owner* is always the blocker: a block applies to the whole store,
 * whichever staff member pressed the button.
 */
class MerchantCustomerSafetyService
{
    /**
     * The partner an order belongs to, if this user works for it (owner or staff).
     */
    public function partnerFor(User $user, Order $order): ?Partner
    {
        $partnerId = $user->workingPartnerId();

        if (! $partnerId || (int) $order->partner_id !== $partnerId) {
            return null;
        }

        return Partner::find($partnerId);
    }

    /**
     * File a high-priority ticket and a report row for the admin queue.
     *
     * @return array{report: ChatReport, ticket: SupportTicket, blocked: bool}
     */
    public function report(User $reporter, Partner $partner, Order $order, string $reason, ?string $details, bool $block): array
    {
        $customerId = (int) $order->customer_id;
        $reasonLabel = ucfirst(str_replace('_', ' ', $reason));

        return DB::transaction(function () use ($reporter, $partner, $order, $customerId, $reason, $reasonLabel, $details, $block) {
            $ticket = SupportTicket::create([
                'user_id' => $reporter->id,
                'order_id' => $order->id,
                'subject' => "Customer report: {$reasonLabel}",
                'description' => trim(implode("\n\n", array_filter([
                    "Reported customer ID: {$customerId}",
                    "Store: {$partner->name} (ID {$partner->id})",
                    "Order ID: {$order->id}",
                    $details ? "Details from store: {$details}" : null,
                ]))),
                'category' => 'other',
                'priority' => 'high',
                'status' => 'open',
                'metadata' => [
                    'type' => 'customer_report',
                    'reason' => $reason,
                    'reported_user_id' => $customerId,
                    'order_id' => $order->id,
                    'partner_id' => $partner->id,
                ],
            ]);

            $report = ChatReport::create([
                'reporter_id' => $reporter->id,
                'reported_user_id' => $customerId,
                'conversation_id' => null,
                'message_id' => null,
                'support_ticket_id' => $ticket->id,
                'reason' => $reason,
                'details' => $details,
                'status' => 'pending',
            ]);

            if ($block) {
                $this->block($partner, $customerId);
            }

            return ['report' => $report, 'ticket' => $ticket, 'blocked' => $block];
        });
    }

    public function block(Partner $partner, int $customerId): void
    {
        UserBlock::firstOrCreate([
            'blocker_id' => (int) $partner->user_id,
            'blocked_id' => $customerId,
        ]);
    }

    public function unblock(Partner $partner, int $customerId): void
    {
        UserBlock::where('blocker_id', (int) $partner->user_id)
            ->where('blocked_id', $customerId)
            ->delete();
    }

    /**
     * One direction only: the store turning the customer away. A customer who
     * blocked someone else is not affected.
     */
    public static function storeBlocksCustomer(Partner $partner, int $customerId): bool
    {
        return UserBlock::where('blocker_id', (int) $partner->user_id)
            ->where('blocked_id', $customerId)
            ->exists();
    }
}
