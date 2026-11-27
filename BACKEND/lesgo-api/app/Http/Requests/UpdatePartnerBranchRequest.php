<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePartnerBranchRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'name'          => ['sometimes', 'required', 'string', 'max:255'],
            'phone_number'  => ['sometimes', 'nullable', 'string', 'max:100'],
            'address_line1' => ['sometimes', 'required', 'string', 'max:255'],
            'address_line2' => ['sometimes', 'nullable', 'string', 'max:255'],
            'city'          => ['sometimes', 'nullable', 'string', 'max:100'],
            'region'        => ['sometimes', 'nullable', 'string', 'max:100'],
            'country'       => ['sometimes', 'nullable', 'string', 'max:100'],
            'postal_code'   => ['sometimes', 'nullable', 'string', 'max:20'],
            'latitude'      => ['sometimes', 'nullable', 'numeric', 'between:-90,90'],
            'longitude'     => ['sometimes', 'nullable', 'numeric', 'between:-180,180'],
            'is_primary'    => ['sometimes', 'nullable', 'boolean'],
            'is_open'       => ['sometimes', 'boolean'],
            'logo_url'      => ['sometimes', 'nullable', 'url', 'max:500'],
            'estimated_delivery_minutes' => ['sometimes', 'nullable', 'integer', 'min:1', 'max:180'],
            'delivery_fee'  => ['sometimes', 'nullable', 'numeric', 'min:0'],
            'opening_hours' => ['sometimes', 'nullable', 'array'],
        ];
    }
}
