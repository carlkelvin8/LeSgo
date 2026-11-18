<?php

namespace Tests\Feature;

use App\Jobs\NotifyMerchantNewOrderJob;
use App\Jobs\SendPushNotificationJob;
use App\Models\Notification;
use App\Models\Order;
use App\Models\Partner;
use App\Models\PartnerStaff;
use App\Models\Service;
use App\Models\User;
use App\Services\FcmService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Kreait\Firebase\Contract\Messaging;
use Mockery;
use Tests\TestCase;

class PushDeliveryTest extends TestCase
{
    use RefreshDatabase;

    public function test_push_is_addressed_to_the_token_with_sound_and_high_priority(): void
    {
        $sent = null;
        $messaging = Mockery::mock(Messaging::class);
        $messaging->shouldReceive('send')->once()->andReturnUsing(function ($message) use (&$sent) {
            $sent = json_decode(json_encode($message), true);
            return [];
        });

        $ok = (new FcmService($messaging))->sendToToken('tok-123', 'New Order!', 'Order #5', ['order_id' => 5, 'meta' => ['a' => 1]]);

        $this->assertTrue($ok);
        $this->assertSame('tok-123', $sent['token']);
        $this->assertSame('New Order!', $sent['notification']['title']);
        $this->assertSame('high', $sent['android']['priority']);
        $this->assertSame('default', $sent['android']['notification']['sound']);
        $this->assertSame('default', $sent['apns']['payload']['aps']['sound']);
        $this->assertSame('10', (string) $sent['apns']['headers']['apns-priority']);
        $this->assertSame('5', $sent['data']['order_id']);
        $this->assertSame('{"a":1}', $sent['data']['meta']);
    }

    public function test_order_alerts_use_the_loud_channel_and_other_pushes_do_not(): void
    {
        $captured = [];
        $messaging = Mockery::mock(Messaging::class);
        $messaging->shouldReceive('send')->twice()->andReturnUsing(function ($message) use (&$captured) {
            $captured[] = json_decode(json_encode($message), true);
            return [];
        });
        $fcm = new FcmService($messaging);

        $fcm->sendToToken('t', 'New Order!', 'b', ['type' => 'new_merchant_order']);
        $fcm->sendToToken('t', 'Payment', 'b', ['type' => 'payment.received']);

        $this->assertSame('lezgo_orders', $captured[0]['android']['notification']['channel_id']);
        $this->assertSame('order_bell', $captured[0]['android']['notification']['sound']);
        $this->assertArrayNotHasKey('channel_id', $captured[1]['android']['notification']);
        $this->assertSame('default', $captured[1]['android']['notification']['sound']);
    }

    public function test_notification_type_is_included_in_the_push_data(): void
    {
        Bus::fake([SendPushNotificationJob::class]);
        $user = User::factory()->create();

        \App\Services\NotificationService::send($user, 'new_order_available', 'T', 'B', ['order_id' => 9], 'push');

        Bus::assertDispatched(SendPushNotificationJob::class, function ($job) {
            $data = (new \ReflectionProperty($job, 'data'))->getValue($job);
            return $data['type'] === 'new_order_available' && $data['order_id'] === 9;
        });
    }

    public function test_send_failure_is_reported_as_false_not_thrown(): void
    {
        $messaging = Mockery::mock(Messaging::class);
        $messaging->shouldReceive('send')->once()->andThrow(new \RuntimeException('unregistered'));

        $this->assertFalse((new FcmService($messaging))->sendToToken('tok', 't', 'b'));
    }

    public function test_multicast_message_has_sound_and_no_single_target(): void
    {
        $sent = null;
        $messaging = Mockery::mock(Messaging::class);
        $messaging->shouldReceive('sendMulticast')->once()->andReturnUsing(function ($message, $tokens) use (&$sent) {
            $sent = json_decode(json_encode($message), true);
            $report = \Kreait\Firebase\Messaging\MulticastSendReport::withItems([
                \Kreait\Firebase\Messaging\SendReport::success(\Kreait\Firebase\Messaging\MessageTarget::with('token', 'a'), []),
                \Kreait\Firebase\Messaging\SendReport::success(\Kreait\Firebase\Messaging\MessageTarget::with('token', 'b'), []),
            ]);
            return $report;
        });

        $result = (new FcmService($messaging))->sendToMultiple(['a', 'b'], 't', 'b');

        $this->assertSame(['success' => 2, 'failure' => 0], $result);
        $this->assertSame('default', $sent['apns']['payload']['aps']['sound']);
        $this->assertArrayNotHasKey('token', $sent);
    }

    public function test_merchant_owner_and_staff_get_a_push_for_a_new_order(): void
    {
        Bus::fake([SendPushNotificationJob::class]);
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $cook = User::factory()->create();
        $partner = Partner::factory()->create(['user_id' => $owner->id]);
        PartnerStaff::create(['partner_id' => $partner->id, 'user_id' => $cook->id, 'role' => 'cook', 'is_active' => true]);
        $order = Order::factory()->create([
            'partner_id' => $partner->id,
            'customer_id' => User::factory()->create()->id,
            'service_id' => Service::factory()->create()->id,
            'status' => 'pending',
        ]);

        (new NotifyMerchantNewOrderJob($order))->handle();

        foreach ([$owner->id, $cook->id] as $userId) {
            $this->assertSame(1, Notification::where('user_id', $userId)->where('type', 'new_merchant_order')->count());
        }
        Bus::assertDispatched(SendPushNotificationJob::class, 2);
    }

    public function test_no_merchant_push_for_cancelled_orders_or_orders_without_a_partner(): void
    {
        Bus::fake([SendPushNotificationJob::class]);
        $owner = User::factory()->create(['role' => 'partner_admin']);
        $partner = Partner::factory()->create(['user_id' => $owner->id]);
        $base = ['customer_id' => User::factory()->create()->id, 'service_id' => Service::factory()->create()->id];

        (new NotifyMerchantNewOrderJob(Order::factory()->create($base + ['partner_id' => $partner->id, 'status' => 'cancelled'])))->handle();
        (new NotifyMerchantNewOrderJob(Order::factory()->create($base + ['partner_id' => null, 'status' => 'pending'])))->handle();

        $this->assertSame(0, Notification::where('type', 'new_merchant_order')->count());
    }
}
