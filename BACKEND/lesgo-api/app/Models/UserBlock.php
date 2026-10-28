<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserBlock extends Model
{
    protected $fillable = [
        'blocker_id',
        'blocked_id',
        'conversation_id',
    ];

    public function blocker()
    {
        return $this->belongsTo(User::class, 'blocker_id');
    }

    public function blocked()
    {
        return $this->belongsTo(User::class, 'blocked_id');
    }

    /**
     * True when either user has blocked the other.
     */
    public static function existsBetween(int $userA, int $userB): bool
    {
        return static::query()
            ->where(function ($q) use ($userA, $userB) {
                $q->where('blocker_id', $userA)->where('blocked_id', $userB);
            })
            ->orWhere(function ($q) use ($userA, $userB) {
                $q->where('blocker_id', $userB)->where('blocked_id', $userA);
            })
            ->exists();
    }
}
