import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../presentation/widgets/notifications/in_app_notification_banner.dart';

/// FCM Service for handling push notifications
/// Note: This is a mock implementation. In production, integrate with firebase_messaging package
@lazySingleton
class FcmService {
  String? _fcmToken;
  final List<Function(Map<String, dynamic>)> _messageHandlers = [];

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // TODO: Initialize Firebase Messaging
      // final messaging = FirebaseMessaging.instance;
      
      // Request permission
      // final settings = await messaging.requestPermission(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      // );

      // Get FCM token
      // _fcmToken = await messaging.getToken();
      
      // Mock token for now
      _fcmToken = 'mock_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
      
      debugPrint('✅ FCM initialized with token: $_fcmToken');

      // Listen to foreground messages
      // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Listen to background messages
      // FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      
    } catch (e) {
      debugPrint('❌ FCM initialization error: $e');
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Register a message handler
  void registerMessageHandler(Function(Map<String, dynamic>) handler) {
    _messageHandlers.add(handler);
  }

  /// Unregister a message handler
  void unregisterMessageHandler(Function(Map<String, dynamic>) handler) {
    _messageHandlers.remove(handler);
  }

  /// Handle foreground message
  void _handleForegroundMessage(Map<String, dynamic> message) {
    debugPrint('📩 Foreground message received: $message');
    
    // Notify all registered handlers
    for (final handler in _messageHandlers) {
      handler(message);
    }
  }

  /// Handle background message (when app is opened from notification)
  void _handleBackgroundMessage(Map<String, dynamic> message) {
    debugPrint('📩 Background message opened: $message');
    
    // Notify all registered handlers
    for (final handler in _messageHandlers) {
      handler(message);
    }
  }

  /// Show in-app notification banner
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

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      // TODO: Implement with Firebase
      // await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      // TODO: Implement with Firebase
      // await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic: $e');
    }
  }

  /// Dispose service
  void dispose() {
    _messageHandlers.clear();
  }
}
