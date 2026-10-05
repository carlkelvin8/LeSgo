<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->isAdmin() ?? false;
    }

    public function rules(): array
    {
        return [
            'name'         => ['required', 'string', 'max:255'],
            'email'        => ['required', 'email', 'max:255', Rule::unique('users', 'email')->whereNull('deleted_at')],
            'phone_number' => ['nullable', 'string', 'max:50'],
            'role'         => ['nullable', 'string', 'in:admin,customer,driver,partner_admin'],
            'password'     => ['required', 'string', 'min:8'],
        ];
    }
}
