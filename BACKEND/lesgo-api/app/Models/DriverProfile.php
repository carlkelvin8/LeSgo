<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DriverProfile extends Model
{
    use HasFactory;

    protected $table = 'driver_profiles';

    protected $fillable = [
        'user_id',
        'partner_id',
        'status',
        'is_available',
        'package_tier',
        'rating',
        'total_trips',
        'license_number',
        'license_expiry_date',
        'id_document_path',
        'documents',
        'last_latitude',
        'last_longitude',
        'vehicle_type',
        'plate_number',
        'vehicle_plate',
    ];

    protected $casts = [
        'is_available' => 'boolean',
        'rating' => 'float',
        'total_trips' => 'integer',
        'license_expiry_date' => 'date',
        'documents' => 'array',
        'last_latitude' => 'float',
        'last_longitude' => 'float',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function partner()
    {
        return $this->belongsTo(Partner::class, 'partner_id');
    }

    public function vehicles()
    {
        return $this->hasMany(Vehicle::class, 'driver_id');
    }

    public function scopeSupportsVehicleType($query, ?string $vehicleType)
    {
        if ($vehicleType === null || trim($vehicleType) === '') {
            return $query;
        }

        $aliases = match (strtolower(trim($vehicleType))) {
            'motor', 'motorcycle' => ['motor', 'motorcycle'],
            default => [strtolower(trim($vehicleType))],
        };

        return $query->where(function ($vehicleQuery) use ($aliases) {
            $vehicleQuery->whereIn('vehicle_type', $aliases)
                ->orWhereHas('vehicles', function ($vehicle) use ($aliases) {
                    $vehicle->whereIn('type', $aliases)
                        ->where('status', 'active');
                });
        });
    }

    /** @return list<string> */
    public function supportedVehicleTypes(): array
    {
        return collect([$this->vehicle_type])
            ->merge(
                $this->vehicles()
                    ->where('status', 'active')
                    ->pluck('type')
            )
            ->filter(fn ($type) => is_string($type) && trim($type) !== '')
            ->map(fn ($type) => strtolower(trim($type)))
            ->flatMap(fn ($type) => in_array($type, ['motor', 'motorcycle'], true)
                ? ['motor', 'motorcycle']
                : [$type])
            ->unique()
            ->values()
            ->all();
    }

    public function supportsVehicleTypeValue(?string $vehicleType): bool
    {
        if ($vehicleType === null || trim($vehicleType) === '') {
            return true;
        }

        return in_array(
            strtolower(trim($vehicleType)),
            $this->supportedVehicleTypes(),
            true
        );
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'driver_id');
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'driver_id');
    }

    public function dutyAttendances()
    {
        return $this->hasMany(DriverDutyAttendance::class);
    }
}
