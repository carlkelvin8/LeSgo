import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'fcm_service.dart';
import '../di/injection.dart';
import '../services/app_preferences_service.dart';
import '../../data/data_source/dto/notification/notification_dto.dart';
import '../constants/routers/app_router.dart';
import '../constants/routers/main/main_routes.dart';

/// Notification types
enum NotificationType {
  orderAccepted('order_accepted', 'Order Accepted', Icons.check_circle, Colors.green),
  orderPickedUp('order_picked_up', 'Order Picked Up', Icons.shopping_bag, Colors.blue),
  orderInTransit('order_in_transit', 'On The Way', Icons.local_shipping, Colors.orange),
  orderDelivered('order_delivered', 'Delivered', Icons.done_all, Colors.green),
  orderCancelled('order_cancelled', 'Order Cancelled', Icons.cancel, Colors.red),
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

/// Notification Service for managing app notifications
@lazySingleton
class NotificationService {
  final FcmService _fcmService;
  final AppPreferencesService _appPrefs = getIt<AppPreferencesService>();
  final List<NotificationDto> _notifications = [];
  int _unreadCount = 0;

  NotificationService(this._fcmService);

  /// Initialize notification service
  Future<void> initialize() async {
    await _fcmService.initialize();
    
    // Register message handler
    _fcmService.registerMessageHandler(_handleNotification);
    
    // Subscribe to user-specific topics
    await _subscribeToUserTopics();
    
    debugPrint('✅ Notification service initialized');
  }

  /// Subscribe to user-specific notification topics
  Future<void> _subscribeToUserTopics() async {
    // Subscribe to general topics
    await _fcmService.subscribeToTopic('all_users');
    await _fcmService.subscribeToTopic('promotions');
    
    // TODO: Subscribe to user-specific topics based on user ID
    // await _fcmService.subscribeToTopic('user_${userId}');
  }

  /// Handle incoming notification
  void _handleNotification(Map<String, dynamic> message) {
    try {
      final type = NotificationType.fromString(
        message['type']?.toString() ?? 'system_alert',
      );
      if (type == NotificationType.promotional &&
          !_appPrefs.pushPromotionsEnabled) {
        return;
      }
      if ((type == NotificationType.orderAccepted ||
              type == NotificationType.orderPickedUp ||
              type == NotificationType.orderInTransit ||
              type == NotificationType.orderDelivered ||
              type == NotificationType.driverAssigned) &&
          !_appPrefs.pushOrderUpdatesEnabled) {
        return;
      }

      final notification = _parseNotification(message);
      _notifications.insert(0, notification);
      
      if (!notification.isRead) {
        _unreadCount++;
      }
      
      debugPrint('📬 Notification received: ${notification.title}');
    } catch (e) {
      debugPrint('❌ Failed to handle notification: $e');
    }
  }

  /// Parse notification from message
  NotificationDto _parseNotification(Map<String, dynamic> message) {
    return NotificationDto(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 0, // TODO: Get from auth
      type: message['type'] ?? 'system_alert',
      title: message['title'] ?? 'Notification',
      message: message['message'] ?? '',
      data: message['data'],
      isRead: false,
      readAt: null,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  /// Show notification banner in app
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

  /// Show notification by type
  void showNotificationByType(
    BuildContext context, {
    required NotificationType type,
    required String message,
    Map<String, dynamic>? data,
    VoidCallback? onTap,
  }) {
    final notification = NotificationDto(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 0,
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

  /// Handle notification tap
  void _handleNotificationTap(BuildContext context, NotificationDto notification) {
    // Mark as read
    markAsRead(notification.id);
    
    // Navigate based on notification type
    final type = NotificationType.fromString(notification.type);
    
    switch (type) {
      case NotificationType.orderAccepted:
      case NotificationType.orderPickedUp:
      case NotificationType.orderInTransit:
      case NotificationType.orderDelivered:
      case NotificationType.driverAssigned:
        // Navigate to order tracking
        final orderId = notification.data?['order_id'];
        if (orderId != null) {
          // TODO: Navigate to tracking screen
          debugPrint('Navigate to order: $orderId');
        }
        break;
      case NotificationType.promotional:
        AppRouter.push(context, MainRoutes.offers);
        break;
      default:
        break;
    }
  }

  /// Mark notification as read
  void markAsRead(int notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      // TODO: Update notification in backend
      debugPrint('✅ Notification $notificationId marked as read');
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    _unreadCount = 0;
    // TODO: Update all notifications in backend
    debugPrint('✅ All notifications marked as read');
  }

  /// Get all notifications
  List<NotificationDto> get notifications => List.unmodifiable(_notifications);

  /// Get unread count
  int get unreadCount => _unreadCount;

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
  }

  /// Dispose service
  void dispose() {
    _fcmService.dispose();
  }
}
