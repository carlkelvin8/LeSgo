<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class FilterOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'status' => ['nullable', 'string', Rule::in([
                'pending',
                'searching_driver',
                'accepted',
                'driver_arrived_at_pickup',
                'ready_for_pickup',
                'in_progress',
                'picked_up',
                'completed',
                'cancelled',
                'scheduled',
            ])],
            'payment_status' => ['nullable', 'string', Rule::in(['pending', 'paid', 'failed', 'refunded'])],
            'service_id'     => ['nullable', 'integer', 'exists:services,id'],
            'partner_branch_id' => ['nullable', 'integer'],
            'per_page'       => ['nullable', 'integer', 'min:1', 'max:100'],
            // Riders: only the orders assigned to me, not the open pool.
            'mine'           => ['nullable', 'boolean'],
        ];
    }
}
