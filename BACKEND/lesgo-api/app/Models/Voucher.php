<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Voucher extends Model
{
    protected $fillable = [
        'code',
        'title',
        'description',
        'discount_text',
        'min_order',
        'type',
        'value',
        'max_discount',
        'min_order_value',
        'max_uses',
        'expires_at',
        'user_restrictions',
        'applicable_services',
        'is_active',
    ];

    protected $casts = [
        'value' => 'decimal:2',
        'max_discount' => 'decimal:2',
        'min_order_value' => 'decimal:2',
        'expires_at' => 'datetime',
        'user_restrictions' => 'array',
        'applicable_services' => 'array',
        'is_active' => 'boolean',
    ];

    protected static function booted(): void
    {
        static::saving(function ($voucher) {
            $voucher->code = strtoupper(trim($voucher->code));
        });
    }

    public function toVoucherArray(): array
    {
        return [
            'code' => $this->code,
            'title' => $this->title,
            'description' => $this->description,
            'discount_text' => $this->discount_text,
            'min_order' => $this->min_order,
            'type' => $this->type,
            'value' => (float) $this->value,
            'max_discount' => $this->max_discount !== null ? (float) $this->max_discount : null,
            'min_order_value' => (float) $this->min_order_value,
            'max_uses' => $this->max_uses,
            'expires_at' => $this->expires_at ? $this->expires_at->format('Y-m-d') : null,
            'user_restrictions' => $this->user_restrictions ?? [],
            'applicable_services' => $this->applicable_services,
            'is_active' => $this->is_active,
        ];
    }
}
