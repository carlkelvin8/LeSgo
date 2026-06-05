import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

import '../../firebase_options.dart';
import '../../presentation/widgets/notifications/in_app_notification_banner.dart';
import '../config/mobile_config_service.dart';
import 'fcm_background_handler.dart';

/// Delivers real FCM push notifications plus local tray display.
@lazySingleton
class FcmService {
  static const _promoChannelId = 'lezgo_promos';
  static const _orderChannelId = 'lezgo_orders';

  String? _fcmToken;
  bool _firebaseReady = false;
  final List<void Function(Map<String, dynamic>)> _messageHandlers = [];
  final List<void Function(String token)> _tokenRefreshListeners = [];
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  VoidCallback? onPromoNotificationTap;

  bool get isFirebaseReady => _firebaseReady;

  Future<void> initialize() async {
    try {
      await _initLocalNotifications();
      await _initFirebaseMessaging();
    } catch (e, stack) {
      debugPrint('❌ FCM initialization error: $e');
      debugPrint('$stack');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
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

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _promoChannelId,
          'Promotions & Offers',
          description: 'Exclusive offers and promos from LEZGO',
          importance: Importance.high,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _orderChannelId,
          'Order Updates',
          description: 'Order status and delivery updates',
          importance: Importance.high,
        ),
      );
    }
  }

  Future<void> _initFirebaseMessaging() async {
    if (kIsWeb) {
      debugPrint('ℹ️ FCM skipped on web');
      return;
    }

    if (!MobileConfigService.instance.isFirebaseConfigured &&
        !DefaultFirebaseOptions.isConfigured) {
      debugPrint(
        '⚠️ Firebase not configured. Set secrets.json or server FIREBASE_* env vars.',
      );
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: MobileConfigService.instance.isFirebaseConfigured
            ? MobileConfigService.instance.currentFirebaseOptions
            : DefaultFirebaseOptions.currentPlatform,
      );
    }

    _firebaseReady = true;
    final messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestNotificationPermissions(messaging);
    await _configurePlatformSettings(messaging);

    _fcmToken = await messaging.getToken();
    debugPrint('✅ FCM token: $_fcmToken');

    messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      debugPrint('🔄 FCM token refreshed');
      for (final listener in List.of(_tokenRefreshListeners)) {
        listener(token);
      }
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedMessage(initialMessage);
    }
  }

  Future<void> _requestNotificationPermissions(FirebaseMessaging messaging) async {
    if (kIsWeb) return;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('⚠️ Push notification permission denied');
    }

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

    if (!kIsWeb && Platform.isIOS) {
      final iosPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _configurePlatformSettings(FirebaseMessaging messaging) async {
    if (Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    if (Platform.isAndroid) {
      await messaging.setAutoInitEnabled(true);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final payload = _remoteMessageToMap(message);
    _dispatchToHandlers(payload);

    final title = payload['title']?.toString();
    final body = payload['message']?.toString();
    if (title == null || body == null || title.isEmpty || body.isEmpty) {
      return;
    }

    final type = payload['type']?.toString() ?? 'system_alert';
    final route = payload['route']?.toString();
    _showLocalTrayNotification(
      title: title,
      body: body,
      payload: route == 'offers' ? 'offers' : null,
      channelId: _channelForType(type),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final payload = _remoteMessageToMap(message);
    _dispatchToHandlers(payload);

    final route = payload['route']?.toString();
    if (route == 'offers') {
      onPromoNotificationTap?.call();
    }
  }

  Map<String, dynamic> _remoteMessageToMap(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    final title = message.notification?.title ??
        data['title']?.toString() ??
        'Notification';
    final body = message.notification?.body ??
        data['message']?.toString() ??
        data['body']?.toString() ??
        '';

    return {
      'title': title,
      'message': body,
      'body': body,
      'type': data['type']?.toString() ?? 'system_alert',
      'route': data['route']?.toString(),
      ...data,
    };
  }

  void _dispatchToHandlers(Map<String, dynamic> message) {
    for (final handler in List.of(_messageHandlers)) {
      handler(message);
    }
  }

  String _channelForType(String type) {
    if (type == 'promotional' || type == 'promo' || type == 'offer') {
      return _promoChannelId;
    }
    return _orderChannelId;
  }

  String? get fcmToken => _fcmToken;

  void registerMessageHandler(void Function(Map<String, dynamic>) handler) {
    _messageHandlers.add(handler);
  }

  void unregisterMessageHandler(void Function(Map<String, dynamic>) handler) {
    _messageHandlers.remove(handler);
  }

  void addTokenRefreshListener(void Function(String token) listener) {
    _tokenRefreshListeners.add(listener);
  }

  void removeTokenRefreshListener(void Function(String token) listener) {
    _tokenRefreshListeners.remove(listener);
  }

  Future<void> showPushNotification({
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
    String? channelId,
  }) async {
    final message = {
      'title': title,
      'message': body,
      'body': body,
      'type': data?['type'] ?? 'promotional',
      'route': data?['route'],
      ...?data,
    };

    _dispatchToHandlers(message);
    await _showLocalTrayNotification(
      title: title,
      body: body,
      payload: payload,
      channelId: channelId ?? _channelForType(message['type']?.toString() ?? ''),
    );
  }

  Future<void> _showLocalTrayNotification({
    required String title,
    required String body,
    String? payload,
    String? channelId,
  }) async {
    if (kIsWeb) return;

    final resolvedChannel = channelId ?? _orderChannelId;
    final channelName = resolvedChannel == _promoChannelId
        ? 'Promotions & Offers'
        : 'Order Updates';
    final channelDescription = resolvedChannel == _promoChannelId
        ? 'Exclusive offers and promos from LEZGO'
        : 'Order status and delivery updates';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        resolvedChannel,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
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
    if (!_firebaseReady) {
      debugPrint('⚠️ Cannot subscribe to $topic — Firebase not ready');
      return;
    }
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('✅ Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_firebaseReady) {
      debugPrint('⚠️ Cannot unsubscribe from $topic — Firebase not ready');
      return;
    }
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    debugPrint('✅ Unsubscribed from topic: $topic');
  }

  void dispose() {
    _messageHandlers.clear();
    _tokenRefreshListeners.clear();
  }
}
