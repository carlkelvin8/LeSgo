<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChatReport extends Model
{
    public const REASONS = [
        'harassment',
        'hate_speech',
        'sexual_content',
        'threats_or_violence',
        'spam_or_scam',
        'other',
    ];

    protected $fillable = [
        'reporter_id',
        'reported_user_id',
        'conversation_id',
        'message_id',
        'support_ticket_id',
        'reason',
        'details',
        'message_snapshot',
        'status',
    ];

    public function reporter()
    {
        return $this->belongsTo(User::class, 'reporter_id');
    }

    public function reportedUser()
    {
        return $this->belongsTo(User::class, 'reported_user_id');
    }

    public function conversation()
    {
        return $this->belongsTo(ChatConversation::class, 'conversation_id');
    }

    public function message()
    {
        return $this->belongsTo(ChatMessage::class, 'message_id');
    }

    public function supportTicket()
    {
        return $this->belongsTo(SupportTicket::class, 'support_ticket_id');
    }
}
