<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Voucher;

class VoucherSeeder extends Seeder
{
    public function run(): void
    {
        $vouchers = [
            [
                'code' => 'WELCOME10',
                'title' => 'Welcome Discount',
                'description' => '10% off your first order',
                'discount_text' => '10% OFF',
                'min_order' => '₱100',
                'type' => 'percentage',
                'value' => 10,
                'max_discount' => 50,
                'min_order_value' => 100,
                'max_uses' => 1000,
                'expires_at' => '2026-12-31',
                'user_restrictions' => ['new_users_only' => true],
                'applicable_services' => null,
                'is_active' => true,
            ],
            [
                'code' => 'SAVE20',
                'title' => 'Save Big',
                'description' => '₱20 off orders above ₱150',
                'discount_text' => '₱20 OFF',
                'min_order' => '₱150',
                'type' => 'fixed',
                'value' => 20,
                'max_discount' => null,
                'min_order_value' => 150,
                'max_uses' => 500,
                'expires_at' => '2026-06-30',
                'user_restrictions' => [],
                'applicable_services' => null,
                'is_active' => true,
            ],
            [
                'code' => 'FREEDEL',
                'title' => 'Free Delivery',
                'description' => 'Free delivery on orders above ₱200',
                'discount_text' => 'FREE DELIVERY',
                'min_order' => '₱200',
                'type' => 'free_delivery',
                'value' => 0,
                'max_discount' => null,
                'min_order_value' => 200,
                'max_uses' => null,
                'expires_at' => null,
                'user_restrictions' => [],
                'applicable_services' => [1, 2],
                'is_active' => true,
            ],
            [
                'code' => 'RIDE20',
                'title' => 'Save on your next ride',
                'description' => 'Get 20% off LesRide bookings around Cagayan de Oro.',
                'discount_text' => '20% OFF',
                'min_order' => '₱100',
                'type' => 'percentage',
                'value' => 20,
                'max_discount' => 80,
                'min_order_value' => 100,
                'max_uses' => null,
                'expires_at' => '2026-12-31',
                'user_restrictions' => [],
                'applicable_services' => [2],
                'is_active' => true,
            ],
            [
                'code' => 'LUNCHFREE',
                'title' => 'Free delivery for lunch',
                'description' => 'Order from partner restaurants and skip the delivery fee.',
                'discount_text' => 'FREE DELIVERY',
                'min_order' => '₱150',
                'type' => 'free_delivery',
                'value' => 0,
                'max_discount' => null,
                'min_order_value' => 150,
                'max_uses' => null,
                'expires_at' => '2026-12-31',
                'user_restrictions' => [],
                'applicable_services' => [3],
                'is_active' => true,
            ],
            [
                'code' => 'PAYBACK',
                'title' => 'LesPay cashback',
                'description' => 'Pay with LesPay wallet and receive cashback credit.',
                'discount_text' => 'P50 BACK',
                'min_order' => '₱200',
                'type' => 'fixed',
                'value' => 50,
                'max_discount' => null,
                'min_order_value' => 200,
                'max_uses' => null,
                'expires_at' => '2026-12-31',
                'user_restrictions' => [],
                'applicable_services' => null,
                'is_active' => true,
            ],
        ];

        foreach ($vouchers as $data) {
            Voucher::updateOrCreate(['code' => $data['code']], $data);
        }
    }
}
