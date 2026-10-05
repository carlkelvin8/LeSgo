import 'fcm_service.dart';
import 'notification_navigation_service.dart';

/// Local notification helpers and backend registration via [FcmService].
class PushNotificationService {
  PushNotificationService._();

  static Future<void> registerWithBackend() =>
      FcmService.instance.registerWithBackend();

  static void handlePayload(String? payload) =>
      NotificationNavigationService.handlePayload(payload);

  static Future<void> show({
    required String title,
    required String body,
    String? payload,
    String channelId = 'lezgo_rider',
    String channelName = 'Rider Updates',
  }) =>
      FcmService.instance.showLocalNotification(
        title: title,
        body: body,
        payload: payload,
        channelId: channelId,
        channelName: channelName,
      );
}
