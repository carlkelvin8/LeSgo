import '../../data/data_source/dto/merchant/order_dto.dart';

class MerchantOrderAmountUtils {
  MerchantOrderAmountUtils._();

  static double itemSubtotal(OrderDto order) {
    final items = order.orderItems;
    if (items == null || items.isEmpty) return 0;

    return items.fold(0.0, (sum, item) => sum + lineTotal(item));
  }

  /// Total for a single order [item]: `unit price × quantity`.
  ///
  /// Mirrors the backend exactly (OrderSettlementService::merchantAmount and
  /// OrderWalletPaymentService::resolvePayableAmount):
  /// `COALESCE(actual_price, estimated_price) * quantity`.
  ///
  /// Both `actual_price` and `estimated_price` are PER-UNIT prices, and the
  /// server stores `estimated_price` with size/flavor/add-on extras already
  /// included (MenuItemOptionsHelper::calculateUnitPrice). The previous code
  /// returned `actual_price` without × quantity and added `selected_options`
  /// extras on top of `estimated_price` again, so revenue, "Credited to
  /// E-Wallet" and line amounts were overstated for orders with add-ons or
  /// with a driver-entered actual price and quantity > 1.
  static double lineTotal(OrderItemDto item) {
    final actual = item.totalPrice;
    final unit = (actual != null && actual > 0) ? actual : (item.unitPrice ?? 0);
    return unit * item.quantity;
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

  /// The day an order is attributed to in every merchant money view
  /// (Analytics, daily summary banner, Sales Report):
  ///  - completed: completed_at (fallback updated_at, then created_at), so an
  ///    order placed 23:50 and delivered 00:20 earns on the delivery day;
  ///  - cancelled: cancelled_at (fallback created_at);
  ///  - still active: created_at.
  static DateTime? earningsDate(OrderDto order) {
    if (isCompleted(order)) {
      return _parseDate(order.completedAt) ??
          _parseDate(order.updatedAt) ??
          _parseDate(order.createdAt);
    }
    if (isCancelled(order)) {
      return _parseDate(order.cancelledAt) ?? _parseDate(order.createdAt);
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

  /// Sales Report range filter: [earningsDate] falls on a local calendar day
  /// from [start] through [end] (both inclusive, times ignored).
  static bool isWithinDateRange(OrderDto order, DateTime start, DateTime end) {
    final date = earningsDate(order);
    if (date == null) return false;
    final from = DateTime(start.year, start.month, start.day);
    final until = DateTime(end.year, end.month, end.day + 1);
    return !date.isBefore(from) && date.isBefore(until);
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
