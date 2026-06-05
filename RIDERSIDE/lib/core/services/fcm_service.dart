import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../config/secrets_config.dart';
import 'api_service.dart';
import 'fcm_background_handler.dart';

class FcmService {
  static final FcmService instance = FcmService._();
  FcmService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _token;
  bool _ready = false;

  String? get token => _token;
  bool get isReady => _ready;

  Future<void> initialize() async {
    if (kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    if (!SecretsConfig.isFirebaseConfigured &&
        !DefaultFirebaseOptions.isConfigured) {
      debugPrint('FCM skipped: configure secrets.json and run tool/sync_secrets.ps1');
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _token = await messaging.getToken();
    _ready = true;
    debugPrint('FCM token: $_token');

    messaging.onTokenRefresh.listen((token) async {
      _token = token;
      await _registerWithBackend(token);
    });

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    if (_token != null) {
      await _registerWithBackend(_token!);
    }
  }

  Future<void> _registerWithBackend(String token) async {
    try {
      await ApiService.registerPushDevice(
        deviceToken: token,
        platform: Platform.isAndroid ? 'android' : 'ios',
      );
      await ApiService.registerFcmToken(token);
    } catch (e) {
      debugPrint('FCM backend registration failed: $e');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lezgo_rider',
          'Rider Updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
