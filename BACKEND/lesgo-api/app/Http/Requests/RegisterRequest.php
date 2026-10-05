<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $isPartnerAdmin = $this->input('role') === 'partner_admin';
        $isCustomer = ($this->input('role') ?? 'customer') === 'customer';

        return [
            'name' => [
                'required',
                'string',
                'max:255',
                'regex:/^[a-zA-Z\s\-\']+$/',
            ],
            'email' => [
                'required',
                'string',
                'email:rfc',
                'max:255',
                Rule::unique('users', 'email')->whereNull('deleted_at'),
            ],
            'phone' => [
                'required',
                'string',
                'max:20',
                'regex:/^[\d\s\+\-\(\)]+$/',
            ],
            'password' => [
                'required',
                'confirmed',
                Password::min(8)
                    ->mixedCase()
                    ->numbers(),
            ],
            'password_confirmation' => [
                'required',
                'string',
            ],
            'address_line_1' => ['nullable', 'string', 'max:255'],
            'address_line_2' => ['nullable', 'string', 'max:255'],
            'is_default' => ['sometimes', 'boolean'],
            'referral_code' => [Rule::excludeIf(!$isCustomer), 'nullable', 'string', 'max:255', Rule::exists('users', 'referral_code')->whereNull('deleted_at')],
            'city' => ['nullable', 'string', 'max:100'],
            'province' => ['nullable', 'string', 'max:100'],
            'zip_code' => ['nullable', 'string', 'max:20'],
            'latitude' => [$isCustomer ? 'required_with:address_line_1' : 'nullable', 'nullable', 'numeric', 'between:-90,90'],
            'longitude' => [$isCustomer ? 'required_with:address_line_1' : 'nullable', 'nullable', 'numeric', 'between:-180,180'],
            'date_of_birth' => ['nullable', 'date', 'before:today'],
            'phone_verification_token' => [$isPartnerAdmin ? 'required' : 'nullable', 'string', 'size:64'],
            'terms_accepted' => ['required', 'boolean', 'accepted'],
            'privacy_accepted' => ['required', 'boolean', 'accepted'],
            'role' => [
                'sometimes',
                'string',
                'in:customer,partner_admin',
            ],
            'device_name' => [
                'nullable',
                'string',
                'max:100',
            ],

            // ── Partner Admin fields ──────────────────────────────────────────
            'restaurant_name'         => [$isPartnerAdmin ? 'required' : 'nullable', 'string', 'max:255'],
            'zip_code'                => ['nullable', 'string', 'max:20'],
            'selfie'                  => [($isPartnerAdmin || $isCustomer) ? 'required' : 'nullable', 'file', $isCustomer ? 'mimes:jpeg,jpg,png' : 'mimes:jpeg,jpg,png,pdf', 'max:10240'],
            'valid_id'                => [$isPartnerAdmin ? 'required' : 'nullable', 'file', 'mimes:jpeg,jpg,png,pdf', 'max:10240'],
            'digital_signature'       => [$isPartnerAdmin ? 'required' : 'nullable', 'file', 'mimes:jpeg,jpg,png,pdf', 'max:10240'],
            'barangay_permit'         => [$isPartnerAdmin ? 'required' : 'nullable', 'file', 'mimes:jpeg,jpg,png,pdf,doc,docx', 'max:10240'],
            'mayors_permit'           => [$isPartnerAdmin ? 'required' : 'nullable', 'file', 'mimes:jpeg,jpg,png,pdf,doc,docx', 'max:10240'],
            'dti_permit'              => [$isPartnerAdmin ? 'required' : 'nullable', 'file', 'mimes:jpeg,jpg,png,pdf,doc,docx', 'max:10240'],
            'selfie_path'             => ['nullable', 'string', 'max:500'],
            'valid_id_path'           => ['nullable', 'string', 'max:500'],
            'digital_signature_path'  => ['nullable', 'string', 'max:500'],
            'barangay_permit_path'    => ['nullable', 'string', 'max:500'],
            'mayors_permit_path'      => ['nullable', 'string', 'max:500'],
            'dti_permit_path'         => ['nullable', 'string', 'max:500'],

            // ── Customer identity verification ──────────────────────────────
            'id_type' => [$isCustomer ? 'required' : 'nullable', 'string', 'in:philippine_national_id,drivers_license,passport,umid,sss_id,postal_id,voters_id,prc_id'],
            'id_number' => [$isCustomer ? 'required' : 'nullable', 'string', 'max:100'],
            'valid_id_front' => [$isCustomer ? 'required' : 'nullable', 'file', 'mimes:jpeg,jpg,png', 'max:10240'],
            'valid_id_back' => [$isCustomer ? 'required' : 'nullable', 'file', 'mimes:jpeg,jpg,png', 'max:10240'],
        ];
    }

    public function messages(): array
    {
        return [
            'latitude.required_with' => 'Please select your address on the map.',
            'longitude.required_with' => 'Please select your address on the map.',
            'referral_code.exists' => 'This referral code was not found. Please check it or leave it blank.',
            'selfie.required' => 'A live selfie is required.',
            'id_type.required' => 'Please select a government ID type.',
            'id_number.required' => 'The government ID number is required.',
            'valid_id_front.required' => 'A photo of the front of the government ID is required.',
            'valid_id_back.required' => 'A photo of the back of the government ID is required.',
        ];
    }

    protected function prepareForValidation(): void
    {
        $phone = $this->input('phone') ?? $this->input('phone_number');
        $referralCode = $this->input('referral_code');

        $this->merge([
            'name'  => trim($this->name ?? ''),
            'email' => strtolower(trim($this->email ?? '')),
            'referral_code' => is_string($referralCode)
                ? (trim($referralCode) === '' ? null : strtoupper(trim($referralCode)))
                : $referralCode,
            // Accept both 'phone' and 'phone_number' field names
            'phone' => is_string($phone) && $phone !== ''
                ? preg_replace('/[^\d\+]/', '', $phone)
                : null,
            'address_line_1' => $this->address_line_1 ?? $this->address ?? null,
            'role'  => $this->role ?? 'customer',
            // Normalize snake_case document field names
            'restaurant_name'         => $this->restaurant_name ?? $this->restaurantName ?? null,
            'selfie_path'             => $this->selfie_path ?? $this->selfiePath ?? null,
            'valid_id_path'           => $this->valid_id_path ?? $this->validIdPath ?? null,
            'digital_signature_path'  => $this->digital_signature_path ?? $this->digitalSignaturePath ?? null,
            'barangay_permit_path'    => $this->barangay_permit_path ?? $this->barangayPermitPath ?? null,
            'mayors_permit_path'      => $this->mayors_permit_path ?? $this->mayorsPermitPath ?? null,
            'dti_permit_path'         => $this->dti_permit_path ?? $this->dtiPermitPath ?? null,
        ]);
    }
}
