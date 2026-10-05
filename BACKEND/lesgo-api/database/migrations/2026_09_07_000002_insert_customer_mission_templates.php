<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $templates = [
            [
                'title' => 'Book 1 LesEat today',
                'description' => 'Order food from any restaurant',
                'type' => 'daily',
                'target_audience' => 'customer',
                'goal_type' => 'leseat_order',
                'goal_target' => 1,
                'reward_amount' => 50.00,
                'reward_currency' => 'PHP',
                'service_code' => null,
                'is_active' => true,
            ],
            [
                'title' => 'Refer 1 friend',
                'description' => 'Invite a friend to join LesGo',
                'type' => 'daily',
                'target_audience' => 'customer',
                'goal_type' => 'friend_referral',
                'goal_target' => 1,
                'reward_amount' => 100.00,
                'reward_currency' => 'PHP',
                'service_code' => null,
                'is_active' => true,
            ],
            [
                'title' => 'Leave us a review',
                'description' => 'Rate our app on the store',
                'type' => 'daily',
                'target_audience' => 'customer',
                'goal_type' => 'app_review',
                'goal_target' => 1,
                'reward_amount' => 25.00,
                'reward_currency' => 'PHP',
                'service_code' => null,
                'is_active' => true,
            ],
            [
                'title' => 'Like our FB page',
                'description' => 'Follow us on social media',
                'type' => 'daily',
                'target_audience' => 'customer',
                'goal_type' => 'social_follow',
                'goal_target' => 1,
                'reward_amount' => 25.00,
                'reward_currency' => 'PHP',
                'service_code' => null,
                'is_active' => true,
            ],
            [
                'title' => 'Book 5 LesRide',
                'description' => 'Complete 5 ride bookings',
                'type' => 'daily',
                'target_audience' => 'customer',
                'goal_type' => 'lesride_orders',
                'goal_target' => 5,
                'reward_amount' => 200.00,
                'reward_currency' => 'PHP',
                'service_code' => null,
                'is_active' => true,
            ],
        ];

        foreach ($templates as $t) {
            DB::table('mission_templates')->updateOrInsert(
                ['title' => $t['title'], 'target_audience' => $t['target_audience']],
                array_merge($t, ['created_at' => now(), 'updated_at' => now()])
            );
        }
    }

    public function down(): void
    {
        DB::table('mission_templates')->where('target_audience', 'customer')->delete();
    }
};
