import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';

import '../../firebase_options.dart';
import '../utils/app_logger.dart';
import 'api_service.dart';
import 'fcm_background_handler.dart';
import 'notification_navigation_service.dart';
import 'notification_payload.dart';
import 'order_sound_alert_service.dart';
import 'secure_storage_service.dart';

class FcmService with WidgetsBindingObserver {
  static final FcmService instance = FcmService._();
  FcmService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _token;
  bool _localNotificationsReady = false;
  bool _fcmReady = false;
  bool _openedListenersReady = false;
  bool _messagingListenersReady = false;
  bool _tokenRequestInProgress = false;
  FirebaseMessaging? _messaging;

  String? get token => _token;
  bool get isReady => _fcmReady;
  bool get isLocalNotificationsReady => _localNotificationsReady;

  Future<void> initialize() async {
    if (kIsWeb) return;

    await _initLocalNotifications();

    // Initialize order sound alert service
    try {
      await OrderSoundAlertService().initialize();
    } catch (e) {
      AppLogger.debug('Could not initialize OrderSoundAlertService: $e');
    }

    // Validate Firebase configuration early
    if (!_validateFirebaseConfiguration()) {
      AppLogger.error(
        'FCM initialization failed: Firebase is not properly configured. '
        'Ensure FIREBASE_PROJECT_ID, FIREBASE_MESSAGING_SENDER_ID, '
        'FIREBASE_API_KEY_ANDROID, and FIREBASE_APP_ID_ANDROID are set via secrets.json '
        'and run: tool/sync_secrets.ps1',
        null,
      );
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      _messaging = messaging;
      WidgetsBinding.instance.addObserver(this);

      try {
        await messaging.requestPermission();
      } catch (e) {
        AppLogger.warn('Could not request push notification permission: $e');
      }

      _setupMessagingListeners(messaging);
      await _refreshFcmToken();

      _setupOpenedNotificationHandlers(messaging);

      unawaited(_handleInitialMessage(messaging));
    } catch (e) {
      AppLogger.error('FCM initialization error', e);
      _fcmReady = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_fcmReady) {
      unawaited(_refreshFcmToken());
    }
  }

  void _setupMessagingListeners(FirebaseMessaging messaging) {
    if (_messagingListenersReady) return;
    _messagingListenersReady = true;

    messaging.onTokenRefresh.listen((token) async {
      _token = token;
      _fcmReady = token.isNotEmpty;
      if (_fcmReady) await registerWithBackend();
    });
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  Future<void> _refreshFcmToken() async {
    final messaging = _messaging;
    if (messaging == null || _tokenRequestInProgress) return;

    _tokenRequestInProgress = true;
    try {
      if (Platform.isIOS) {
        String? apnsToken;
        for (var attempt = 0; attempt < 5; attempt++) {
          apnsToken = await messaging.getAPNSToken();
          if (apnsToken != null && apnsToken.isNotEmpty) break;
          if (attempt < 4) {
            await Future<void>.delayed(const Duration(milliseconds: 300));
          }
        }

        if (apnsToken == null || apnsToken.isEmpty) {
          _token = null;
          _fcmReady = false;
          AppLogger.warn(
            'APNs token is not available yet. FCM token retrieval will retry '
            'when the app returns to the foreground.',
          );
          return;
        }
      }

      _token = await messaging.getToken();
      _fcmReady = _token != null && _token!.isNotEmpty;
      AppLogger.debug(
        'FCM initialized: token ${_fcmReady ? "received" : "missing"}',
      );
    } catch (e) {
      _token = null;
      _fcmReady = false;
      AppLogger.warn('Could not retrieve FCM token yet: $e');
    } finally {
      _tokenRequestInProgress = false;
    }
  }

  Future<void> _handleInitialMessage(FirebaseMessaging messaging) async {
    try {
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _queueOpenedMessage(initialMessage);
      }
    } catch (e) {
      AppLogger.debug('Could not read initial push message: $e');
    }
  }

  /// Validates the platform options compiled into the app.
  bool _validateFirebaseConfiguration() {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (!DefaultFirebaseOptions.isConfigured ||
        options.projectId.isEmpty ||
        options.messagingSenderId.isEmpty ||
        options.apiKey.isEmpty ||
        options.appId.isEmpty) {
      AppLogger.error(
        'Firebase validation failed: platform Firebase options are incomplete',
        null,
      );
      return false;
    }

    if (options.projectId.startsWith('your-') ||
        options.projectId.startsWith('YOUR_') ||
        options.apiKey.startsWith('your-') ||
        options.apiKey.startsWith('YOUR_')) {
      AppLogger.error(
        'Firebase validation failed: platform Firebase options contain placeholders',
        null,
      );
      return false;
    }

    return true;
  }

  /// Registers the current FCM token after login or session restore.
  Future<void> registerWithBackend() async {
    final token = _token;
    if (!_fcmReady || token == null || token.isEmpty) {
      AppLogger.debug(
        'FCM backend registration skipped: no FCM token available',
      );
      return;
    }

    final authToken = await SecureStorageService.getToken();
    if (authToken == null || authToken.isEmpty) {
      AppLogger.debug('FCM backend registration skipped: not authenticated');
      return;
    }

    try {
      await ApiService.registerPushToken(
        fcmToken: token,
        platform: Platform.isAndroid ? 'android' : 'ios',
      );
    } catch (e) {
      AppLogger.error('FCM backend registration failed', e);
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'lezgo_rider',
    String channelName = 'Rider Updates',
  }) async {
    if (!_localNotificationsReady || kIsWeb) return;

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Orders, status updates, and messages',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> _initLocalNotifications() async {
    if (_localNotificationsReady) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    if (!kIsWeb) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _localNotificationsReady = true;
  }

  void _setupOpenedNotificationHandlers(FirebaseMessaging messaging) {
    if (_openedListenersReady) return;
    _openedListenersReady = true;

    FirebaseMessaging.onMessageOpenedApp.listen(_queueOpenedMessage);
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    NotificationNavigationService.handlePayload(response.payload);
  }

  void _queueOpenedMessage(RemoteMessage message) {
    final payload = _extractPayload(message);
    if (payload != null) {
      NotificationNavigationService.handlePayload(payload);
    }
  }

  String? _extractPayload(RemoteMessage message) {
    final fromData = NotificationPayload.fromRemoteData(message.data);
    if (fromData != null) {
      return _payloadToString(fromData);
    }
    return null;
  }

  String? _payloadToString(NotificationPayload payload) {
    switch (payload.type) {
      case NotificationTargetType.order:
        final id = payload.orderId;
        return id == null ? null : 'order_$id';
      case NotificationTargetType.chatByOrder:
        final id = payload.orderId;
        return id == null ? null : 'chat_order_$id';
      case NotificationTargetType.chatByConversation:
        final id = payload.conversationId;
        return id == null ? null : 'chat_$id';
      case NotificationTargetType.merchantOrders:
        return 'merchant_order';
      case NotificationTargetType.inbox:
        return 'inbox';
      case NotificationTargetType.unknown:
        return null;
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Check if this is an order notification
    final isOrderNotification = _isOrderNotification(message);

    if (isOrderNotification) {
      // Play order alert sound
      try {
        await OrderSoundAlertService().playOrderAlert();
      } catch (e) {
        AppLogger.debug('Could not play order alert sound: $e');
      }
    }

    await showLocalNotification(
      title: notification.title ?? 'LeSgo Affiliates',
      body: notification.body ?? '',
      payload: _extractPayload(message),
    );
  }

  /// Check if the message is an order notification
  bool _isOrderNotification(RemoteMessage message) {
    final data = message.data;
    final notificationType = data['type'] ?? data['notification_type'] ?? '';
    final hasOrderId = data['order_id'] != null || data['orderId'] != null;

    return notificationType.toLowerCase().contains('order') || hasOrderId;
  }
}
