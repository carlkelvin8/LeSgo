<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ChatMessage extends Model
{
    use HasFactory;

    /** sender_type values of messages sent by a store's owner or staff. */
    public const STORE_SENDER_TYPES = ['partner_admin', 'partner_staff'];

    protected $fillable = [
        'conversation_id',
        'sender_id',
        'sender_type',
        'message_type',
        'content',
        'attachments',
        'read_at',
        'store_read_at',
        'is_system_message',
        'metadata',
    ];

    protected $casts = [
        'attachments' => 'array',
        'read_at' => 'datetime',
        'store_read_at' => 'datetime',
        'is_system_message' => 'boolean',
        'metadata' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Relationships

    public function conversation()
    {
        return $this->belongsTo(ChatConversation::class, 'conversation_id');
    }

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    // Scopes

    public function scopeUnread($query)
    {
        return $query->whereNull('read_at');
    }

    /**
     * Unread for the store (owner/staff) of the order: tracked in store_read_at,
     * separate from the customer/rider read_at. The store's own messages never
     * count as unread for the store.
     */
    public function scopeUnreadByStore($query)
    {
        return $query->whereNull('store_read_at')
            ->whereNotIn('sender_type', self::STORE_SENDER_TYPES);
    }

    public function scopeByType($query, string $type)
    {
        return $query->where('message_type', $type);
    }

    public function scopeSystemMessages($query)
    {
        return $query->where('is_system_message', true);
    }

    public function scopeUserMessages($query)
    {
        return $query->where('is_system_message', false);
    }

    // Helper methods

    public function markAsRead(): void
    {
        if (!$this->read_at) {
            $this->update(['read_at' => now()]);
        }
    }

    public function markAsReadByStore(): void
    {
        if (!$this->store_read_at) {
            $this->update(['store_read_at' => now()]);
        }
    }

    public function isUnread(): bool
    {
        return $this->read_at === null;
    }

    public function isSystemMessage(): bool
    {
        return $this->is_system_message;
    }

    public function hasAttachments(): bool
    {
        return !empty($this->attachments);
    }
}