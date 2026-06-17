import '../../data/data_source/dto/merchant/order_dto.dart';

class MerchantOrderAmountUtils {
  MerchantOrderAmountUtils._();

  static double itemSubtotal(OrderDto order) {
    final items = order.orderItems;
    if (items == null || items.isEmpty) return 0;

    var total = 0.0;
    for (final item in items) {
      final lineTotal = item.totalPrice ??
          ((item.unitPrice ?? 0) * item.quantity);
      total += lineTotal;
    }
    return total;
  }

  static double foodEarnings(OrderDto order) {
    final itemsTotal = itemSubtotal(order);
    if (itemsTotal > 0) return itemsTotal;

    if (order.partnerShare != null && order.partnerShare! > 0) {
      return order.partnerShare!;
    }
    if (order.metaOrderValue != null && order.metaOrderValue! > 0) {
      return order.metaOrderValue!;
    }
    if (order.fareBreakdownSubtotal != null &&
        order.fareBreakdownSubtotal! > 0) {
      return order.fareBreakdownSubtotal!;
    }
    return 0;
  }

  static bool isCompleted(OrderDto order) =>
      order.status.toLowerCase() == 'completed';

  static bool isCancelled(OrderDto order) =>
      order.status.toLowerCase() == 'cancelled';

  static bool isPendingEarnings(OrderDto order) {
    if (isCompleted(order) || isCancelled(order)) return false;
    // Only orders that are picked up or in delivery are pending earnings
    const pendingStatuses = {
      'picked_up',
      'in_progress',
      'driver_arrived_at_pickup',
    };
    return pendingStatuses.contains(order.status.toLowerCase());
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Use completion date for delivered orders; otherwise order creation date.
  static DateTime? earningsDate(OrderDto order) {
    if (isCompleted(order)) {
      return _parseDate(order.completedAt) ??
          _parseDate(order.updatedAt) ??
          _parseDate(order.createdAt);
    }
    return _parseDate(order.createdAt);
  }

  static bool isWithinPeriod(OrderDto order, MerchantEarningsPeriod period) {
    if (period == MerchantEarningsPeriod.all) return true;

    final date = earningsDate(order);
    if (date == null) return false;

    final now = DateTime.now();
    switch (period) {
      case MerchantEarningsPeriod.today:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case MerchantEarningsPeriod.week:
        final start = now.subtract(const Duration(days: 6));
        final startOfDay = DateTime(start.year, start.month, start.day);
        return !date.isBefore(startOfDay);
      case MerchantEarningsPeriod.month:
        return date.year == now.year && date.month == now.month;
      case MerchantEarningsPeriod.all:
        return true;
    }
  }
}

enum MerchantEarningsPeriod {
  today,
  week,
  month,
  all;

  String get label {
    switch (this) {
      case MerchantEarningsPeriod.today:
        return 'Today';
      case MerchantEarningsPeriod.week:
        return 'This Week';
      case MerchantEarningsPeriod.month:
        return 'This Month';
      case MerchantEarningsPeriod.all:
        return 'All Time';
    }
  }
}
