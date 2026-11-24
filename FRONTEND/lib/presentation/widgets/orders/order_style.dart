import 'package:flutter/material.dart';

import '../../../core/utils/order_status_mapper.dart';

/// How an order status looks in lists: label, colour and icon.
class OrderStatusStyle {
  const OrderStatusStyle(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

/// Shared look for services and statuses so Order History and Transactions
/// speak the same visual language.
class OrderStyle {
  OrderStyle._();

  static OrderStatusStyle status(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'pending':
      case 'searching_driver':
        return const OrderStatusStyle(
          'Finding driver',
          Color(0xFFEF8A1B),
          Icons.hourglass_top_rounded,
        );
      case 'scheduled':
        return const OrderStatusStyle(
          'Scheduled',
          Color(0xFF5C6BC0),
          Icons.schedule_rounded,
        );
      case 'accepted':
      case 'driver_assigned':
        return const OrderStatusStyle(
          'Accepted',
          Color(0xFF1E88E5),
          Icons.check_circle_outline_rounded,
        );
      case 'preparing':
      case 'cooking':
        return const OrderStatusStyle(
          'Preparing',
          Color(0xFFF59E0B),
          Icons.soup_kitchen_outlined,
        );
      case 'driver_arrived':
      case 'driver_arrived_at_pickup':
        return const OrderStatusStyle(
          'Driver arrived',
          Color(0xFF8E24AA),
          Icons.directions_bike_rounded,
        );
      case 'ready_for_pickup':
        return const OrderStatusStyle(
          'Ready for pickup',
          Color(0xFF1E88E5),
          Icons.inventory_2_outlined,
        );
      case 'picked_up':
      case 'pickedup':
        return const OrderStatusStyle(
          'Picked up',
          Color(0xFF3949AB),
          Icons.shopping_bag_outlined,
        );
      case 'in_progress':
      case 'in_transit':
      case 'intransit':
      case 'on_the_way':
      case 'delivering':
        return const OrderStatusStyle(
          'On the way',
          Color(0xFF00897B),
          Icons.local_shipping_outlined,
        );
      case 'completed':
      case 'delivered':
        return const OrderStatusStyle(
          'Completed',
          Color(0xFF2E9E5B),
          Icons.check_circle_rounded,
        );
      case 'cancelled':
      case 'canceled':
        return const OrderStatusStyle(
          'Cancelled',
          Color(0xFFE5484D),
          Icons.cancel_rounded,
        );
      case 'failed':
        return const OrderStatusStyle(
          'Failed',
          Color(0xFFE5484D),
          Icons.error_rounded,
        );
      default:
        return OrderStatusStyle(
          OrderStatusMapper.toDisplayLabel(raw),
          const Color(0xFF757575),
          Icons.info_outline_rounded,
        );
    }
  }

  static IconData serviceIcon(String service) {
    switch (service) {
      case 'LesGo':
        return Icons.inventory_2_rounded;
      case 'LesRide':
        return Icons.two_wheeler_rounded;
      case 'LesEat':
        return Icons.restaurant_rounded;
      case 'LesBuy':
        return Icons.shopping_bag_rounded;
      case 'LesTransport':
        return Icons.airport_shuttle_rounded;
      case 'LesPay':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  static Color serviceColor(String service) {
    switch (service) {
      case 'LesGo':
        return const Color(0xFFE84C8B);
      case 'LesRide':
        return const Color(0xFF6B4CE6);
      case 'LesEat':
        return const Color(0xFFFF7A2F);
      case 'LesBuy':
        return const Color(0xFF3FA55B);
      case 'LesTransport':
        return const Color(0xFFE5484D);
      default:
        return const Color(0xFF5F2D82);
    }
  }

  /// "cash" -> "Cash", "wallet" -> "LesPay", "xendit" -> "Online".
  static String paymentMethodLabel(String? method) {
    switch ((method ?? '').trim().toLowerCase()) {
      case '':
        return 'Cash';
      case 'cash':
        return 'Cash';
      case 'wallet':
      case 'lespay':
        return 'LesPay';
      case 'xendit':
      case 'card':
      case 'online':
      case 'mobile_money':
        return 'Online';
      default:
        final m = method!.trim();
        return m[0].toUpperCase() + m.substring(1);
    }
  }
}
