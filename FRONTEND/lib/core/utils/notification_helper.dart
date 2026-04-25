import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../di/injection.dart';

/// Helper class for showing notifications throughout the app
class NotificationHelper {
  static final NotificationService _service = getIt<NotificationService>();

  /// Show order accepted notification
  static void showOrderAccepted(
    BuildContext context, {
    required String orderId,
    String? driverName,
  }) {
    _service.showNotificationByType(
      context,
      type: NotificationType.orderAccepted,
      message: driverName != null
          ? '$driverName has accepted your order'
          : 'Your order has been accepted',
      data: {'order_id': orderId},
    );
  }

  /// Show order picked up notification
  static void showOrderPickedUp(
    BuildContext context, {
    required String orderId,
    String? driverName,
  }) {
    _service.showNotificationByType(
      context,
      type: NotificationType.orderPickedUp,
      message: driverName != null
          ? '$driverName has picked up your order'
          : 'Your order has been picked up',
      data: {'order_id': orderId},
    );
  }

  /// Show order in transit notification
  static void showOrderInTransit(
    BuildContext context, {
    required String orderId,
    String? eta,
  }) {
    _service.showNotificationByType(
      context,
      type: NotificationType.orderInTransit,
      message: eta != null
          ? 'Your order is on the way. ETA: $eta'
          : 'Your order is on the way',
      data: {'order_id': orderId},
    );
  }

  /// Show order delivered notification
  static void showOrderDelivered(
    BuildContext context, {
    required String orderId,
  }) {
    _service.showNotificationByType(
      context,
      type: NotificationType.orderDelivered,
      message: 'Your order has been delivered successfully!',
      data: {'order_id': orderId},
    );
  }

  /// Show order cancelled notification
  static void showOrderCancelled(
    BuildContext context, {
    required String orderId,
    String? reason,
  }) {
    _service.showNotificationByType(
      context,
      type: NotificationType.orderCancelled,
      message: reason ?? 'Your order has been cancelled',
      data: {'order_id': orderId},
    );
  }

  /// Show driver assigned notification
  static void showDriverAssigned(
    BuildContext context, {
    required String orderId,
    required String driverName,
    String? vehicleNumber,
  }) {
    final message = vehicleNumber != null
        ? '$driverName ($vehicleNumber) is your driver'
        : '$driverName is your driver';
    
    _service.showNotificationByType(
      context,
      type: NotificationType.driverAssigned,
      message: message,
      data: {'order_id': orderId},
    );
  }

  /// Show promotional notification
  static void showPromotion(
    BuildContext context, {
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) {
    _service.showNotificationByType(
      context,
      type: NotificationType.promotional,
      message: message,
      data: data,
    );
  }

  /// Show system alert notification
  static void showSystemAlert(
    BuildContext context, {
    required String message,
    Map<String, dynamic>? data,
  }) {
    _service.showNotificationByType(
      context,
      type: NotificationType.systemAlert,
      message: message,
      data: data,
    );
  }
}
