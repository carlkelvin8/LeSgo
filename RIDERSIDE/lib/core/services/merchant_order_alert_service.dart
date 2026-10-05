import 'package:flutter/services.dart';
import 'order_sound_alert_service.dart';
import 'push_notification_service.dart';

class MerchantOrderAlertService {
  MerchantOrderAlertService._();

  static Future<void> alertNewOrder({required String orderRef, bool playSound = true}) async {
    // Play persistent looping sound for merchant orders
    if (playSound) {
      try {
        await OrderSoundAlertService().playOrderAlert();
      } catch (e) {
        // Fallback to system sound if custom sound fails
        try {
          await SystemSound.play(SystemSoundType.alert);
        } catch (_) {}
      }
    }

    await PushNotificationService.show(
      title: 'New Order!',
      body: '$orderRef is waiting for your acceptance.',
      payload: 'merchant_order',
      channelId: 'lezgo_merchant_orders',
      channelName: 'Merchant Orders',
    );
  }
  
  /// Stop persistent order alert sound
  static Future<void> acknowledgeOrderAlert() async {
    await OrderSoundAlertService().acknowledgeOrderAlert();
  }
}
