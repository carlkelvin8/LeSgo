<?php

namespace App\Models;

use App\Services\MediaStorageService;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Partner extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'logo_url',
        'cover_image_url',
        'description',
        'category',
        'tags',
        'cuisine_types',
        'rating',
        'total_reviews',
        'delivery_fee',
        'min_order_amount',
        'estimated_delivery_minutes',
        'is_open',
        'is_featured',
        'accepts_online_payment',
        'opening_hours',
        'legal_name',
        'slug',
        'business_type',
        'tax_id',
        'support_email',
        'support_phone',
        'status',
        'documents',
    ];

    protected $casts = [
        'tags'                       => 'array',
        'cuisine_types'              => 'array',
        'opening_hours'              => 'array',
        'documents'                  => 'array',
        'rating'                     => 'float',
        'delivery_fee'               => 'float',
        'total_reviews'              => 'integer',
        'min_order_amount'           => 'integer',
        'estimated_delivery_minutes' => 'integer',
        'is_open'                    => 'boolean',
        'is_featured'                => 'boolean',
        'accepts_online_payment'     => 'boolean',
        'created_at'                 => 'datetime',
        'updated_at'                 => 'datetime',
    ];

    protected $appends = ['slug', 'latitude', 'longitude']; // Always include in JSON responses

    /**
     * Get the latitude from the primary branch (or first branch).
     */
    public function getLatitudeAttribute(): ?float
    {
        $branch = $this->relationLoaded('branches')
            ? $this->branches->firstWhere('is_primary', true) ?? $this->branches->first()
            : $this->branches()->where('is_primary', true)->first() ?? $this->branches()->first();

        return $branch?->latitude;
    }

    /**
     * Get the longitude from the primary branch (or first branch).
     */
    public function getLongitudeAttribute(): ?float
    {
        $branch = $this->relationLoaded('branches')
            ? $this->branches->firstWhere('is_primary', true) ?? $this->branches->first()
            : $this->branches()->where('is_primary', true)->first() ?? $this->branches()->first();

        return $branch?->longitude;
    }

    /**
     * Get the slug attribute, generating one if it doesn't exist
     * Note: does not persist to DB to avoid write-on-read side effect (use observer or seeder for backfill)
     */
    public function getSlugAttribute($value)
    {
        if (!empty($value)) {
            return $value;
        }

        if (!empty($this->name)) {
            $base = \Illuminate\Support\Str::slug($this->name);
            $slug = $base;
            $i = 1;
            while (Partner::where('slug', $slug)->where('id', '!=', $this->id)->exists()) {
                $slug = "{$base}-{$i}";
                $i++;
            }
            // Keep in memory for this request only — no DB write on read
            $this->attributes['slug'] = $slug;

            return $slug;
        }

        return 'partner-' . $this->id;
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function branches()
    {
        return $this->hasMany(PartnerBranch::class, 'partner_id');
    }

    public function staff()
    {
        return $this->hasMany(PartnerStaff::class, 'partner_id');
    }

    public function services()
    {
        return $this->hasMany(Service::class, 'partner_id');
    }

    public function driverProfiles()
    {
        return $this->hasMany(DriverProfile::class, 'partner_id');
    }

    public function vehicles()
    {
        return $this->hasMany(Vehicle::class, 'partner_id');
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'partner_id');
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'partner_id');
    }

    public function menuCategories()
    {
        return $this->hasMany(MenuCategory::class, 'partner_id');
    }

    public function menuItems()
    {
        return $this->hasManyThrough(MenuItem::class, MenuCategory::class, 'partner_id', 'menu_category_id');
    }

    protected function logoUrl(): Attribute
    {
        return Attribute::make(
            get: fn ($value) => MediaStorageService::publicUrl($value) ?? $value,
        );
    }

    protected function coverImageUrl(): Attribute
    {
        return Attribute::make(
            get: fn ($value) => MediaStorageService::publicUrl($value) ?? $value,
        );
    }
}
