import 'package:flutter/services.dart';
import 'push_notification_service.dart';

class MerchantOrderAlertService {
  MerchantOrderAlertService._();

  static Future<void> alertNewOrder({required String orderRef}) async {
    HapticFeedback.heavyImpact();

    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    await PushNotificationService.show(
      title: 'New Order!',
      body: '$orderRef is waiting for your acceptance.',
      payload: 'merchant_order',
      channelId: 'lezgo_merchant_orders',
      channelName: 'Merchant Orders',
    );
  }
}
