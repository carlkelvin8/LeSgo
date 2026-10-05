<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SecuritySetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'setting_key',
        'setting_value',
        'data_type',
        'description',
        'category',
        'is_sensitive',
        'requires_restart',
        'updated_by',
        'metadata',
    ];

    protected $casts = [
        'metadata' => 'array',
        'is_sensitive' => 'boolean',
        'requires_restart' => 'boolean',
    ];

    /**
     * Get the typed value based on data_type
     */
    public function getTypedValueAttribute()
    {
        return match ($this->data_type) {
            'boolean' => filter_var($this->setting_value, FILTER_VALIDATE_BOOLEAN),
            'integer' => (int) $this->setting_value,
            'json' => json_decode($this->setting_value, true),
            default => $this->setting_value
        };
    }

    /**
     * Set the value with proper type conversion
     */
    public function setTypedValue(mixed $value): void
    {
        $this->setting_value = match ($this->data_type) {
            'boolean' => $value ? '1' : '0',
            'integer' => (string) $value,
            'json' => json_encode($value, JSON_THROW_ON_ERROR),
            default => (string) $value
        };
    }

    /**
     * Scope by category
     */
    public function scopeByCategory($query, string $category)
    {
        return $query->where('category', $category);
    }

    /**
     * Scope for sensitive settings
     */
    public function scopeSensitive($query)
    {
        return $query->where('is_sensitive', true);
    }

    /**
     * Get a setting value by key
     */
    public static function getValue(string $key, $default = null)
    {
        $setting = static::where('setting_key', $key)->first();

        return $setting ? $setting->typed_value : $default;
    }

    /**
     * Set a setting value by key
     */
    public static function setValue(string $key, mixed $value, ?string $updatedBy = null): void
    {
        $setting = static::firstOrNew(['setting_key' => $key]);

        if (! $setting->exists) {
            $setting->data_type = static::inferDataType($value);
            $setting->category = static::inferCategory($key);
        }

        $setting->setTypedValue($value);
        $setting->updated_by = $updatedBy;
        $setting->save();
    }

    private static function inferDataType(mixed $value): string
    {
        return match (true) {
            is_bool($value) => 'boolean',
            is_int($value) => 'integer',
            is_array($value), is_object($value) => 'json',
            default => 'string',
        };
    }

    private static function inferCategory(string $key): string
    {
        $separatorPosition = strpos($key, '.');

        return $separatorPosition === false
            ? 'general'
            : substr($key, 0, $separatorPosition);
    }
}
