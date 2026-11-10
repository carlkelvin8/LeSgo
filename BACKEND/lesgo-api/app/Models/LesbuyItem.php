<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LesbuyItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'menu_item_id',
        'name',
        'quantity',
        'unit',
        'notes',
        'selected_options',
        'image_url',
        'estimated_price',
        'actual_price',
        'is_checklist_item',
        'status',
    ];

    protected $casts = [
        'quantity'          => 'integer',
        'menu_item_id'      => 'integer',
        'estimated_price'   => 'decimal:2',
        'actual_price'      => 'decimal:2',
        'is_checklist_item' => 'boolean',
        'selected_options'  => 'array',
    ];

    /**
     * An item with no options must read as null: PHP encodes an empty array as
     * `[]`, and released apps expect an object here and fail the whole order list.
     */
    public function getSelectedOptionsAttribute($value): ?array
    {
        $options = is_string($value) ? json_decode($value, true) : $value;

        return is_array($options) && $options !== [] ? $options : null;
    }

    public function order()
    {
        return $this->belongsTo(Order::class);
    }
}
