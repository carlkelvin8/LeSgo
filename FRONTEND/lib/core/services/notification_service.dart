import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'fcm_service.dart';
import '../di/injection.dart';
import '../services/chat_realtime_service.dart';
import '../di/local_storage_service.dart';
import '../services/app_preferences_service.dart';
import '../constants/routers/app_router.dart';
import '../constants/routers/main/main_routes.dart';
import '../../data/data_source/dto/notification/notification_dto.dart';
import '../../data/data_source/notification_remote_datasource.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';

/// Notification types
enum NotificationType {
  orderAccepted('order_accepted', 'Order Accepted', Icons.check_circle, Colors.green),
  orderPickedUp('order_picked_up', 'Order Picked Up', Icons.shopping_bag, Colors.blue),
  orderInTransit('order_in_transit', 'On The Way', Icons.local_shipping, Colors.orange),
  orderDelivered('order_delivered', 'Delivered', Icons.done_all, Colors.green),
  orderCancelled('order_cancelled', 'Order Cancelled', Icons.cancel, Colors.red),
  orderRatingReminder('order_rating_reminder', 'Rate Your Delivery', Icons.star_half, Color(0xFFFF9800)),
  driverAssigned('driver_assigned', 'Driver Assigned', Icons.person, Color(0xFF5F2D82)),
  promotional('promotional', 'Special Offer', Icons.local_offer, Color(0xFFFFC107)),
  systemAlert('system_alert', 'System Alert', Icons.info, Colors.blue);

  final String value;
  final String title;
  final IconData icon;
  final Color color;

  const NotificationType(this.value, this.title, this.icon, this.color);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.systemAlert,
    );
  }
}

@lazySingleton
class NotificationService {
  final FcmService _fcmService;
  final NotificationRemoteDataSource _remoteDs =
      getIt<NotificationRemoteDataSource>();
  final DioClient _dioClient = getIt<DioClient>();
  final LocalStorageService _localStorage = getIt<LocalStorageService>();
  final AppPreferencesService _appPrefs = getIt<AppPreferencesService>();

  final List<NotificationDto> _notifications = [];
  int _unreadCount = 0;
  int? _userId;

  NotificationService(this._fcmService);

  Future<void> initialize() async {
    await _fcmService.initialize();
    _fcmService.registerMessageHandler(_handlePushMessage);
    await _syncFromBackend();
    await _subscribeToUserTopics();
    debugPrint('✅ Notification service initialized');
  }

  Future<void> refreshFromBackend() => _syncFromBackend();

  Future<void> _syncFromBackend() async {
    if (_localStorage.token == null || _localStorage.token!.isEmpty) {
      return;
    }

    try {
      final response = await _remoteDs.fetchNotifications();
      _notifications
        ..clear()
        ..addAll(response.data);
      _unreadCount = await _remoteDs.fetchUnreadCount();
    } catch (e) {
      debugPrint('⚠️ Notification sync failed: $e');
    }
  }

  Future<void> _subscribeToUserTopics() async {
    await _fcmService.subscribeToTopic('all_users');
    await _fcmService.subscribeToTopic('promotions');

    try {
      if (_localStorage.token == null) return;
      final me = await _dioClient.dio.get(ApiConstants.authMe);
      final data = me.data['data'] as Map<String, dynamic>? ?? {};
      _userId = (data['id'] as num?)?.toInt();
      if (_userId != null) {
        await _fcmService.subscribeToTopic('user_$_userId');
      }
    } catch (e) {
      debugPrint('⚠️ User topic subscription skipped: $e');
    }
  }

  void _handlePushMessage(Map<String, dynamic> message) {
    try {
      final typeStr = message['type']?.toString() ?? 'system_alert';
      if (typeStr.toLowerCase().contains('chat') ||
          typeStr.toLowerCase().contains('message') ||
          message['data'] is Map &&
              ((message['data'] as Map)['conversation_id'] != null ||
                  (message['data'] as Map)['order_id'] != null)) {
        getIt<ChatRealtimeService>().notifyChatUpdate();
      }

      final type = NotificationType.fromString(typeStr);
      if (!_shouldDeliver(type)) return;

      final notification = _parseNotification(message);
      _notifications.insert(0, notification);
      if (!notification.isRead) {
        _unreadCount++;
      }
    } catch (e) {
      debugPrint('❌ Failed to handle notification: $e');
    }
  }

  bool _shouldDeliver(NotificationType type) {
    if (type == NotificationType.promotional &&
        !_appPrefs.pushPromotionsEnabled) {
      return false;
    }
    if ((type == NotificationType.orderAccepted ||
            type == NotificationType.orderPickedUp ||
            type == NotificationType.orderInTransit ||
            type == NotificationType.orderDelivered ||
            type == NotificationType.driverAssigned) &&
        !_appPrefs.pushOrderUpdatesEnabled) {
      return false;
    }
    return true;
  }

  NotificationDto _parseNotification(Map<String, dynamic> message) {
    return NotificationDto(
      id: message['id'] is num
          ? (message['id'] as num).toInt()
          : DateTime.now().millisecondsSinceEpoch,
      userId: _userId ?? 0,
      type: message['type']?.toString() ?? 'system_alert',
      title: message['title']?.toString() ?? 'Notification',
      message: message['message']?.toString() ?? message['body']?.toString() ?? '',
      data: message['data'] is Map
          ? Map<String, dynamic>.from(message['data'] as Map)
          : null,
      isRead: false,
      readAt: null,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  void showNotification(
    BuildContext context,
    NotificationDto notification, {
    VoidCallback? onTap,
  }) {
    final type = NotificationType.fromString(notification.type);
    _fcmService.showInAppNotification(
      context,
      title: notification.title,
      message: notification.message,
      icon: type.icon,
      backgroundColor: type.color,
      onTap: onTap ?? () => _handleNotificationTap(context, notification),
    );
  }

  void showNotificationByType(
    BuildContext context, {
    required NotificationType type,
    required String message,
    Map<String, dynamic>? data,
    VoidCallback? onTap,
  }) {
    final notification = NotificationDto(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: _userId ?? 0,
      type: type.value,
      title: type.title,
      message: message,
      data: data,
      isRead: false,
      readAt: null,
      createdAt: DateTime.now().toIso8601String(),
    );

    _notifications.insert(0, notification);
    _unreadCount++;
    showNotification(context, notification, onTap: onTap);
  }

  void _handleNotificationTap(BuildContext context, NotificationDto notification) {
    markAsRead(notification.id);
    final type = NotificationType.fromString(notification.type);

    switch (type) {
      case NotificationType.orderAccepted:
      case NotificationType.orderPickedUp:
      case NotificationType.orderInTransit:
      case NotificationType.orderDelivered:
      case NotificationType.driverAssigned:
        final orderId = notification.data?['order_id'];
        if (orderId != null) {
          debugPrint('Open order tracking: $orderId');
        }
        break;
      case NotificationType.orderRatingReminder:
        AppRouter.push(context, MainRoutes.inbox);
        break;
      case NotificationType.promotional:
        AppRouter.push(context, MainRoutes.offers);
        break;
      default:
        break;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;

    if (!_notifications[index].isRead) {
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      _notifications[index] = NotificationDto(
        id: _notifications[index].id,
        userId: _notifications[index].userId,
        type: _notifications[index].type,
        title: _notifications[index].title,
        message: _notifications[index].message,
        data: _notifications[index].data,
        isRead: true,
        readAt: DateTime.now().toIso8601String(),
        createdAt: _notifications[index].createdAt,
      );
    }

    try {
      await _remoteDs.markRead(notificationId);
    } catch (e) {
      debugPrint('⚠️ markRead API failed: $e');
    }
  }

  Future<void> markAllAsRead() async {
    _unreadCount = 0;
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = NotificationDto(
          id: _notifications[i].id,
          userId: _notifications[i].userId,
          type: _notifications[i].type,
          title: _notifications[i].title,
          message: _notifications[i].message,
          data: _notifications[i].data,
          isRead: true,
          readAt: DateTime.now().toIso8601String(),
          createdAt: _notifications[i].createdAt,
        );
      }
    }

    try {
      await _remoteDs.markAllRead();
    } catch (e) {
      debugPrint('⚠️ markAllRead API failed: $e');
    }
  }

  List<NotificationDto> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;

  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
  }

  void dispose() {
    _fcmService.dispose();
  }
}
