<?php

namespace App\Http\Controllers\Api;

use App\Models\ChatConversation;
use App\Models\ChatMessage;
use App\Models\ChatReport;
use App\Models\Order;
use App\Models\SupportTicket;
use App\Models\UserBlock;
use App\Events\TypingIndicator;
use App\Events\ReadReceipt;
use App\Services\ChatContentFilter;
use App\Services\RealtimeService;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function __construct(
        private RealtimeService $realtimeService,
        private ChatContentFilter $contentFilter
    ) {}
    /**
     * List user's chat conversations.
     */
    public function conversations(Request $request): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validate([
            'status' => 'nullable|in:active,ended',
            'per_page' => 'nullable|integer|min:1|max:100',
        ]);

        $query = ChatConversation::forUser($user->id)
            ->with([
                'customer:id,name,email,profile_photo_url',
                'driver:id,name,email,profile_photo_url',
                'latestMessage',
                'order:id,status',
            ]);

        if (!empty($validated['status'])) {
            $query->where('status', $validated['status']);
        }

        $perPage = (int) ($validated['per_page'] ?? 20);
        $conversations = $query->orderByDesc('last_message_at')->paginate($perPage);

        // Add unread count to each conversation
        $conversations->getCollection()->transform(function ($conversation) use ($user) {
            $conversation->unread_count = $conversation->unreadMessages()
                ->where('sender_id', '!=', $user->id)
                ->count();
            return $conversation;
        });

        return $this->success($conversations, 'Conversations retrieved successfully');
    }

    /**
     * Get or create a conversation for an order.
     */
    public function getOrCreateConversation(Request $request, $orderId): JsonResponse
    {
        $user = $request->user();

        $order = Order::with(['customer', 'driverProfile.user'])->find($orderId);

        if (!$order) {
            return $this->error('Order not found.', 404);
        }

        // Check if user is part of this order
        $isCustomer = (int) $order->customer_id === (int) $user->id;
        $isDriver = $order->driverProfile && (int) $order->driverProfile->user_id === (int) $user->id;

        if (!$isCustomer && !$isDriver && !$user->isAdmin()) {
            return $this->error('Forbidden', 403);
        }

        // Find or create conversation (search by order_id only to avoid duplicates)
        $conversation = ChatConversation::firstOrCreate(
            ['order_id' => $orderId],
            [
                'customer_id' => $order->customer_id,
                'driver_id' => $order->driverProfile ? $order->driverProfile->user_id : null,
                'status' => 'active',
            ]
        );

        // Update driver_id if it was null when created (driver assigned after chat opened)
        $currentDriverId = $order->driverProfile ? $order->driverProfile->user_id : null;
        if ($currentDriverId && !$conversation->driver_id) {
            $conversation->update(['driver_id' => $currentDriverId]);
        }

        $conversation->load([
            'customer:id,name,email,profile_photo_url',
            'driver:id,name,email,profile_photo_url',
            'order:id,status',
        ]);

        $this->appendBlockState($conversation, $user->id);

        return $this->success($conversation, 'Conversation retrieved successfully');
    }

    /**
     * Get messages for a conversation.
     */
    public function messages(Request $request, $conversationId): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validate([
            'page' => 'nullable|integer|min:1',
            'per_page' => 'nullable|integer|min:1|max:100',
        ]);

        $conversation = ChatConversation::forUser($user->id)->find($conversationId);

        if (!$conversation) {
            return $this->error('Conversation not found.', 404);
        }

        $page = (int) ($validated['page'] ?? 1);
        $perPage = (int) ($validated['per_page'] ?? 50);

        $messages = $conversation->messages()
            ->with('sender:id,name,email,role,profile_photo_url')
            ->orderByDesc('created_at')
            ->paginate($perPage, ['*'], 'page', $page);

        // Mark messages as read for the current user
        $conversation->unreadMessages()
            ->where('sender_id', '!=', $user->id)
            ->get()
            ->each->markAsRead();

        return $this->success($messages, 'Messages retrieved successfully');
    }

    /**
     * Send a message in a conversation.
     */
    public function sendMessage(Request $request, $conversationId): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validate([
            'message' => 'required|string|max:5000',
            'attachments' => 'nullable|array',
        ]);

        $conversation = ChatConversation::forUser($user->id)
            ->where('status', 'active')
            ->find($conversationId);

        if (!$conversation) {
            return $this->error('Conversation not found or ended.', 404);
        }

        $otherId = $this->otherParticipantId($conversation, $user->id);
        if ($otherId && UserBlock::existsBetween($user->id, $otherId)) {
            return $this->error('You can no longer send messages in this conversation.', 403);
        }

        // Create message
        $message = $conversation->messages()->create([
            'sender_id' => $user->id,
            'sender_type' => $user->role,
            'message_type' => 'text',
            'content' => $this->contentFilter->clean($validated['message']),
            'attachments' => $validated['attachments'] ?? null,
            'is_system_message' => false,
        ]);

        // Update conversation's last message time
        $conversation->updateLastMessageTime();

        // Broadcast via RealtimeService
        $this->realtimeService->broadcastChatMessage($message, $conversation, $user);

        $message->load('sender:id,name,email,role,profile_photo_url');

        return $this->created($message, 'Message sent successfully');
    }

    /**
     * Send typing indicator in a conversation.
     */
    public function sendTypingIndicator(Request $request, $conversationId): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validate([
            'is_typing' => 'required|boolean',
        ]);

        $conversation = ChatConversation::forUser($user->id)
            ->where('status', 'active')
            ->find($conversationId);

        if (!$conversation) {
            return $this->error('Conversation not found or ended.', 404);
        }

        // Broadcast typing indicator
        broadcast(new TypingIndicator($conversation, $user, $validated['is_typing']));

        return $this->success([
            'conversation_id' => $conversationId,
            'user_id' => $user->id,
            'is_typing' => $validated['is_typing'],
        ], 'Typing indicator sent successfully');
    }

    /**
     * Mark messages as read and broadcast read receipt.
     */
    public function markMessagesAsRead(Request $request, $conversationId): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validate([
            'message_ids' => 'nullable|array',
            'message_ids.*' => 'required|integer',
        ]);

        $conversation = ChatConversation::forUser($user->id)->find($conversationId);

        if (!$conversation) {
            return $this->error('Conversation not found.', 404);
        }

        // Mark unread messages as read
        $query = $conversation->unreadMessages()
            ->where('sender_id', '!=', $user->id);

        if (!empty($validated['message_ids'])) {
            $query->whereIn('id', $validated['message_ids']);
        }

        $messages = $query->get();
        $messages->each->markAsRead();

        // Broadcast read receipt for last message
        if ($messages->isNotEmpty()) {
            $lastMessage = $messages->sortByDesc('id')->first();
            broadcast(new ReadReceipt($lastMessage, $user));
        }

        return $this->success([
            'marked_count' => $messages->count(),
        ], 'Messages marked as read successfully');
    }

    /**
     * Send a system message in a conversation.
     */
    public function sendSystemMessage(Request $request, $conversationId): JsonResponse
    {
        $user = $request->user();

        // Only staff can send system messages
        if (!$user->isAdmin() && !$user->isPartnerAdmin()) {
            return $this->error('Forbidden', 403);
        }

        $validated = $request->validate([
            'message' => 'required|string|max:2000',
        ]);

        $conversation = ChatConversation::find($conversationId);

        if (!$conversation) {
            return $this->error('Conversation not found.', 404);
        }

        // Create system message
        $message = $conversation->messages()->create([
            'sender_id' => $user->id,
            'sender_type' => 'system',
            'message_type' => 'system',
            'content' => $validated['message'],
            'is_system_message' => true,
        ]);

        $conversation->updateLastMessageTime();

        return $this->created($message, 'System message sent successfully');
    }

    /**
     * End a conversation.
     */
    public function endConversation(Request $request, $conversationId): JsonResponse
    {
        $user = $request->user();

        $conversation = ChatConversation::forUser($user->id)->find($conversationId);

        if (!$conversation) {
            return $this->error('Conversation not found.', 404);
        }

        // Only staff can end conversations
        if (!$user->isAdmin() && !$user->isPartnerAdmin()) {
            return $this->error('Only staff can end conversations.', 403);
        }

        $conversation->markAsEnded();

        // Add system message
        $conversation->messages()->create([
            'sender_id' => $user->id,
            'sender_type' => 'system',
            'message_type' => 'system',
            'content' => 'Conversation has been ended by ' . $user->name,
            'is_system_message' => true,
        ]);

        return $this->success([
            'conversation_id' => $conversation->id,
            'status' => 'ended',
        ], 'Conversation ended successfully');
    }

    /**
     * Report the other participant or one of their messages to LeSgo admins.
     * Creates a high-priority support ticket so it lands in the admin queue.
     */
    public function report(Request $request, $conversationId): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validate([
            'reason' => 'required|string|in:' . implode(',', ChatReport::REASONS),
            'details' => 'nullable|string|max:1000',
            'message_id' => 'nullable|integer',
            'block' => 'nullable|boolean',
        ]);

        $conversation = ChatConversation::forUser($user->id)->find($conversationId);

        if (!$conversation) {
            return $this->error('Conversation not found.', 404);
        }

        $reportedUserId = $this->otherParticipantId($conversation, $user->id);

        $message = null;
        if (!empty($validated['message_id'])) {
            $message = $conversation->messages()
                ->where('id', $validated['message_id'])
                ->where('sender_id', '!=', $user->id)
                ->first();

            if (!$message) {
                return $this->error('Message not found.', 404);
            }
        }

        $reasonLabel = ucfirst(str_replace('_', ' ', $validated['reason']));

        $ticket = SupportTicket::create([
            'user_id' => $user->id,
            'order_id' => $conversation->order_id,
            'subject' => "Chat report: {$reasonLabel}",
            'description' => trim(implode("\n\n", array_filter([
                "Reported user ID: " . ($reportedUserId ?? 'unknown'),
                "Conversation ID: {$conversation->id}",
                $message ? "Reported message: \"{$message->content}\"" : null,
                !empty($validated['details']) ? "Details from reporter: {$validated['details']}" : null,
            ]))),
            'category' => 'other',
            'priority' => 'high',
            'status' => 'open',
            'metadata' => [
                'type' => 'chat_report',
                'reason' => $validated['reason'],
                'reported_user_id' => $reportedUserId,
                'conversation_id' => $conversation->id,
                'message_id' => $message?->id,
            ],
        ]);

        $report = ChatReport::create([
            'reporter_id' => $user->id,
            'reported_user_id' => $reportedUserId,
            'conversation_id' => $conversation->id,
            'message_id' => $message?->id,
            'support_ticket_id' => $ticket->id,
            'reason' => $validated['reason'],
            'details' => $validated['details'] ?? null,
            'message_snapshot' => $message?->content,
            'status' => 'pending',
        ]);

        if (($validated['block'] ?? false) && $reportedUserId) {
            $this->blockUser($user->id, $reportedUserId, $conversation->id);
        }

        return $this->created([
            'report_id' => $report->id,
            'ticket_number' => $ticket->ticket_number,
            'blocked' => (bool) ($validated['block'] ?? false) && $reportedUserId !== null,
        ], 'Thanks for reporting. Our team will review this within 24 hours.');
    }

    /**
     * Block the other participant: neither side can send further messages.
     */
    public function block(Request $request, $conversationId): JsonResponse
    {
        $user = $request->user();
        $conversation = ChatConversation::forUser($user->id)->find($conversationId);

        if (!$conversation) {
            return $this->error('Conversation not found.', 404);
        }

        $otherId = $this->otherParticipantId($conversation, $user->id);
        if (!$otherId) {
            return $this->error('There is no one to block in this conversation yet.', 422);
        }

        $this->blockUser($user->id, $otherId, $conversation->id);

        return $this->success([
            'conversation_id' => $conversation->id,
            'blocked_by_me' => true,
            'can_message' => false,
        ], 'User blocked.');
    }

    /**
     * Remove a block the current user placed on the other participant.
     */
    public function unblock(Request $request, $conversationId): JsonResponse
    {
        $user = $request->user();
        $conversation = ChatConversation::forUser($user->id)->find($conversationId);

        if (!$conversation) {
            return $this->error('Conversation not found.', 404);
        }

        $otherId = $this->otherParticipantId($conversation, $user->id);
        if ($otherId) {
            UserBlock::where('blocker_id', $user->id)->where('blocked_id', $otherId)->delete();
        }

        $this->appendBlockState($conversation, $user->id);

        return $this->success([
            'conversation_id' => $conversation->id,
            'blocked_by_me' => $conversation->blocked_by_me,
            'can_message' => $conversation->can_message,
        ], 'User unblocked.');
    }

    private function blockUser(int $blockerId, int $blockedId, int $conversationId): void
    {
        UserBlock::firstOrCreate(
            ['blocker_id' => $blockerId, 'blocked_id' => $blockedId],
            ['conversation_id' => $conversationId]
        );
    }

    private function otherParticipantId(ChatConversation $conversation, int $userId): ?int
    {
        if ((int) $conversation->customer_id === $userId) {
            return $conversation->driver_id ? (int) $conversation->driver_id : null;
        }

        if ((int) $conversation->driver_id === $userId) {
            return $conversation->customer_id ? (int) $conversation->customer_id : null;
        }

        return null;
    }

    private function appendBlockState(ChatConversation $conversation, int $userId): void
    {
        $otherId = $this->otherParticipantId($conversation, $userId);

        $conversation->blocked_by_me = $otherId
            ? UserBlock::where('blocker_id', $userId)->where('blocked_id', $otherId)->exists()
            : false;
        $conversation->can_message = !$otherId || !UserBlock::existsBetween($userId, $otherId);
    }

    /**
     * Get unread message count for the user.
     */
    public function unreadCount(Request $request): JsonResponse
    {
        $user = $request->user();

        $count = ChatMessage::whereIn('conversation_id', function ($query) use ($user) {
            $query->select('id')
                ->from('chat_conversations')
                ->where(function ($q) use ($user) {
                    $q->where('customer_id', $user->id)
                      ->orWhere('driver_id', $user->id);
                })
                ->where('status', 'active');
        })
            ->whereNull('read_at')
            ->where('sender_id', '!=', $user->id)
            ->count();

        return $this->success([
            'count' => $count,
            'unread_count' => $count,
        ], 'Unread count retrieved successfully');
    }
}