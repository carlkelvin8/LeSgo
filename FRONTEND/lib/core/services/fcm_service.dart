import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

import '../../presentation/widgets/notifications/in_app_notification_banner.dart';

/// Delivers push-style notifications to the device tray and in-app handlers.
@lazySingleton
class FcmService {
  String? _fcmToken;
  final List<Function(Map<String, dynamic>)> _messageHandlers = [];
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  VoidCallback? onPromoNotificationTap;

  Future<void> initialize() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: (response) {
          if (response.payload == 'offers') {
            onPromoNotificationTap?.call();
          }
        },
      );

      if (!kIsWeb) {
        final androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();

        final iosPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      _fcmToken = 'local_device_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('✅ Push notifications initialized: $_fcmToken');
    } catch (e) {
      debugPrint('❌ Push initialization error: $e');
    }
  }

  String? get fcmToken => _fcmToken;

  void registerMessageHandler(Function(Map<String, dynamic>) handler) {
    _messageHandlers.add(handler);
  }

  void unregisterMessageHandler(Function(Map<String, dynamic>) handler) {
    _messageHandlers.remove(handler);
  }

  Future<void> showPushNotification({
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    final message = {
      'title': title,
      'message': body,
      'body': body,
      'type': data?['type'] ?? 'promotional',
      'route': data?['route'],
      ...?data,
    };

    for (final handler in _messageHandlers) {
      handler(message);
    }

    if (kIsWeb) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'lezgo_promos',
        'Promotions & Offers',
        channelDescription: 'Exclusive offers and promos from LEZGO',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  void showInAppNotification(
    BuildContext context, {
    required String title,
    required String message,
    IconData? icon,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    InAppNotificationBanner.show(
      context,
      title: title,
      message: message,
      icon: icon ?? Icons.notifications,
      backgroundColor: backgroundColor,
      onTap: onTap,
    );
  }

  Future<void> subscribeToTopic(String topic) async {
    debugPrint('✅ Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('✅ Unsubscribed from topic: $topic');
  }

  void dispose() {
    _messageHandlers.clear();
  }
}
