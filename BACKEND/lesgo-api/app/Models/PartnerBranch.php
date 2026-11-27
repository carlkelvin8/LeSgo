<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PartnerBranch extends Model
{
    use HasFactory;

    protected $table = 'partner_branches';

    protected $fillable = [
        'partner_id',
        'name',
        'logo_url',
        'phone_number',
        'address_line1',
        'address_line2',
        'city',
        'region',
        'country',
        'postal_code',
        'latitude',
        'longitude',
        'is_primary',
        'is_open',
        'estimated_delivery_minutes',
        'delivery_fee',
        'opening_hours',
    ];

    protected $casts = [
        'latitude'                   => 'float',
        'longitude'                  => 'float',
        'is_primary'                 => 'boolean',
        'is_open'                    => 'boolean',
        'delivery_fee'               => 'decimal:2',
        'estimated_delivery_minutes' => 'integer',
        'opening_hours'              => 'array',
        'created_at'                 => 'datetime',
        'updated_at'                 => 'datetime',
    ];

    public function partner()
    {
        return $this->belongsTo(Partner::class, 'partner_id');
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'partner_branch_id');
    }

    public function hasCoordinates(): bool
    {
        return $this->latitude !== null && $this->longitude !== null
            && ! ($this->latitude == 0.0 && $this->longitude == 0.0);
    }

    public function fullAddress(): string
    {
        return collect([
            $this->address_line1,
            $this->address_line2,
            $this->city,
            $this->region,
        ])->filter(fn ($part) => filled($part))->implode(', ');
    }

    /**
     * Snapshot stored on each order so the pickup branch stays readable
     * even if the branch is later renamed, moved or deleted.
     */
    public function toOrderSnapshot(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'address' => $this->fullAddress(),
            'phone_number' => $this->phone_number,
            'lat' => $this->latitude,
            'lng' => $this->longitude,
        ];
    }
}
