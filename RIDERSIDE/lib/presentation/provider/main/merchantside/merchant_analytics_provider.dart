import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/merchant_order_amount_utils.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import 'merchant_orders_provider.dart';
import 'merchant_profile_provider.dart';
import 'merchant_reviews_provider.dart';

class MerchantTopItem {
  final String name;
  final int quantitySold;
  final double revenue;
  final int? menuItemId;

  const MerchantTopItem({
    required this.name,
    required this.quantitySold,
    required this.revenue,
    this.menuItemId,
  });
}

class MerchantTrendPoint {
  final String label;
  final int orderCount;
  final double revenue;

  const MerchantTrendPoint({
    required this.label,
    required this.orderCount,
    required this.revenue,
  });
}

class MerchantPeakHour {
  final int hour;
  final int orderCount;

  const MerchantPeakHour({
    required this.hour,
    required this.orderCount,
  });

  String get displayLabel {
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$hour12 $period';
  }
}

class MerchantAnalyticsSummary {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int activeOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final double cancellationRate;
  final List<MerchantTrendPoint> trend;
  final List<MerchantPeakHour> peakHours;
  final List<MerchantTopItem> topItems;
  final double averageRating;
  final int totalReviews;

  const MerchantAnalyticsSummary({
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.activeOrders = 0,
    this.totalRevenue = 0,
    this.averageOrderValue = 0,
    this.cancellationRate = 0,
    this.trend = const [],
    this.peakHours = const [],
    this.topItems = const [],
    this.averageRating = 0,
    this.totalReviews = 0,
  });
}

final merchantAnalyticsPeriodProvider =
    StateProvider<MerchantEarningsPeriod>((ref) {
  return MerchantEarningsPeriod.week;
});

final merchantAnalyticsSummaryProvider =
    Provider<AsyncValue<MerchantAnalyticsSummary>>((ref) {
  final ordersAsync = ref.watch(merchantOrdersProvider);
  final period = ref.watch(merchantAnalyticsPeriodProvider);
  final profile = ref.watch(merchantProfileProvider).valueOrNull;
  final reviewsAsync = ref.watch(merchantReviewsDashboardProvider);

  final rating = reviewsAsync.maybeWhen(
    data: (dashboard) => dashboard.statistics.averageRating,
    orElse: () => profile?.rating ?? 0,
  );
  final totalReviews = reviewsAsync.maybeWhen(
    data: (dashboard) => dashboard.statistics.totalReviews,
    orElse: () => profile?.totalReviews ?? 0,
  );

  return ordersAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (orders) => AsyncValue.data(
      _buildSummary(
        orders,
        period,
        averageRating: rating,
        totalReviews: totalReviews,
      ),
    ),
  );
});

final merchantWeekAnalyticsPreviewProvider =
    Provider<AsyncValue<MerchantAnalyticsSummary>>((ref) {
  final ordersAsync = ref.watch(merchantOrdersProvider);
  final profile = ref.watch(merchantProfileProvider).valueOrNull;
  final reviewsAsync = ref.watch(merchantReviewsDashboardProvider);

  final rating = reviewsAsync.maybeWhen(
    data: (dashboard) => dashboard.statistics.averageRating,
    orElse: () => profile?.rating ?? 0,
  );
  final totalReviews = reviewsAsync.maybeWhen(
    data: (dashboard) => dashboard.statistics.totalReviews,
    orElse: () => profile?.totalReviews ?? 0,
  );

  return ordersAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (orders) => AsyncValue.data(
      _buildSummary(
        orders,
        MerchantEarningsPeriod.week,
        averageRating: rating,
        totalReviews: totalReviews,
      ),
    ),
  );
});

final merchantTodayOrderCountProvider = Provider<AsyncValue<int>>((ref) {
  final ordersAsync = ref.watch(merchantOrdersProvider);

  return ordersAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (orders) {
      final count = orders
          .where((o) => _isOrderCreatedInPeriod(o, MerchantEarningsPeriod.today))
          .length;
      return AsyncValue.data(count);
    },
  );
});

MerchantAnalyticsSummary _buildSummary(
  List<OrderDto> orders,
  MerchantEarningsPeriod period, {
  required double averageRating,
  required int totalReviews,
}) {
  var totalOrders = 0;
  var completedOrders = 0;
  var cancelledOrders = 0;
  var activeOrders = 0;
  var totalRevenue = 0.0;

  final itemMap = <String, MerchantTopItem>{};
  final hourlyCounts = List<int>.filled(24, 0);
  final trendBuckets = _createTrendBuckets(period);

  for (final order in orders) {
    if (!_isOrderCreatedInPeriod(order, period)) continue;

    totalOrders += 1;
    _addToTrend(trendBuckets, order, period);

    if (MerchantOrderAmountUtils.isCompleted(order)) {
      completedOrders += 1;
      if (_isRevenueInPeriod(order, period)) {
        final amount = MerchantOrderAmountUtils.foodEarnings(order);
        if (amount > 0) {
          totalRevenue += amount;
          _accumulateTopItems(itemMap, order, amount);
        }
      }
      final hour = _orderHour(order);
      if (hour != null) hourlyCounts[hour] += 1;
    } else if (MerchantOrderAmountUtils.isCancelled(order)) {
      cancelledOrders += 1;
    } else {
      activeOrders += 1;
    }
  }

  final finished = completedOrders + cancelledOrders;
  final cancellationRate =
      finished > 0 ? (cancelledOrders / finished) * 100 : 0.0;
  final averageOrderValue =
      completedOrders > 0 ? totalRevenue / completedOrders : 0.0;

  final peakHours = <MerchantPeakHour>[];
  for (var hour = 0; hour < 24; hour++) {
    if (hourlyCounts[hour] > 0) {
      peakHours.add(MerchantPeakHour(hour: hour, orderCount: hourlyCounts[hour]));
    }
  }
  peakHours.sort((a, b) => b.orderCount.compareTo(a.orderCount));
  final topPeakHours = peakHours.take(5).toList();

  final topItems = itemMap.values.toList()
    ..sort((a, b) {
      final qty = b.quantitySold.compareTo(a.quantitySold);
      return qty != 0 ? qty : b.revenue.compareTo(a.revenue);
    });

  return MerchantAnalyticsSummary(
    totalOrders: totalOrders,
    completedOrders: completedOrders,
    cancelledOrders: cancelledOrders,
    activeOrders: activeOrders,
    totalRevenue: totalRevenue,
    averageOrderValue: averageOrderValue,
    cancellationRate: cancellationRate,
    trend: trendBuckets,
    peakHours: topPeakHours,
    topItems: topItems.take(8).toList(),
    averageRating: averageRating,
    totalReviews: totalReviews,
  );
}

List<MerchantTrendPoint> _createTrendBuckets(MerchantEarningsPeriod period) {
  final now = DateTime.now();

  switch (period) {
    case MerchantEarningsPeriod.today:
      return List.generate(24, (hour) {
        final label = hour % 6 == 0 ? _formatHour(hour) : '';
        return MerchantTrendPoint(label: label, orderCount: 0, revenue: 0);
      });
    case MerchantEarningsPeriod.week:
      return List.generate(7, (index) {
        final day = now.subtract(Duration(days: 6 - index));
        return MerchantTrendPoint(
          label: _weekdayLabel(day.weekday),
          orderCount: 0,
          revenue: 0,
        );
      });
    case MerchantEarningsPeriod.month:
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      return List.generate(daysInMonth, (index) {
        final day = index + 1;
        final label = day == 1 || day % 7 == 0 ? '$day' : '';
        return MerchantTrendPoint(label: label, orderCount: 0, revenue: 0);
      });
    case MerchantEarningsPeriod.all:
      return List.generate(30, (index) {
        final day = now.subtract(Duration(days: 29 - index));
        final label = index == 0 || index == 29 || index % 7 == 0
            ? '${day.month}/${day.day}'
            : '';
        return MerchantTrendPoint(label: label, orderCount: 0, revenue: 0);
      });
  }
}

void _addToTrend(
  List<MerchantTrendPoint> trend,
  OrderDto order,
  MerchantEarningsPeriod period,
) {
  final date = _parseDate(order.createdAt);
  if (date == null) return;

  int index;
  switch (period) {
    case MerchantEarningsPeriod.today:
      index = date.hour;
      break;
    case MerchantEarningsPeriod.week:
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
      index = date.difference(start).inDays.clamp(0, 6);
      break;
    case MerchantEarningsPeriod.month:
      index = date.day - 1;
      break;
    case MerchantEarningsPeriod.all:
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 29));
      index = date.difference(start).inDays.clamp(0, 29);
      break;
  }

  if (index < 0 || index >= trend.length) return;

  final point = trend[index];
  final revenue = MerchantOrderAmountUtils.isCompleted(order)
      ? MerchantOrderAmountUtils.foodEarnings(order)
      : 0.0;

  trend[index] = MerchantTrendPoint(
    label: point.label,
    orderCount: point.orderCount + 1,
    revenue: point.revenue + revenue,
  );
}

void _accumulateTopItems(
  Map<String, MerchantTopItem> itemMap,
  OrderDto order,
  double orderRevenue,
) {
  final items = order.orderItems;
  if (items == null || items.isEmpty) {
    final key = 'order-${order.id}';
    itemMap[key] = MerchantTopItem(
      name: 'Order #${order.referenceNumber ?? order.id}',
      quantitySold: 1,
      revenue: orderRevenue,
    );
    return;
  }

  for (final item in items) {
    final key = item.menuItemId?.toString() ?? item.itemName.trim().toLowerCase();
    final lineRevenue = item.totalPrice ??
        ((item.unitPrice ?? 0) * item.quantity);
    final existing = itemMap[key];
    if (existing == null) {
      itemMap[key] = MerchantTopItem(
        name: item.itemName,
        quantitySold: item.quantity,
        revenue: lineRevenue,
        menuItemId: item.menuItemId,
      );
    } else {
      itemMap[key] = MerchantTopItem(
        name: existing.name,
        quantitySold: existing.quantitySold + item.quantity,
        revenue: existing.revenue + lineRevenue,
        menuItemId: existing.menuItemId ?? item.menuItemId,
      );
    }
  }
}

bool _isOrderCreatedInPeriod(OrderDto order, MerchantEarningsPeriod period) {
  if (period == MerchantEarningsPeriod.all) return true;
  final date = _parseDate(order.createdAt);
  if (date == null) return false;
  return _isDateInPeriod(date, period);
}

bool _isRevenueInPeriod(OrderDto order, MerchantEarningsPeriod period) {
  return MerchantOrderAmountUtils.isWithinPeriod(order, period);
}

bool _isDateInPeriod(DateTime date, MerchantEarningsPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case MerchantEarningsPeriod.today:
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    case MerchantEarningsPeriod.week:
      final start = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
      return !date.isBefore(start);
    case MerchantEarningsPeriod.month:
      return date.year == now.year && date.month == now.month;
    case MerchantEarningsPeriod.all:
      return true;
  }
}

DateTime? _parseDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return DateTime.parse(raw).toLocal();
  } catch (_) {
    return null;
  }
}

int? _orderHour(OrderDto order) {
  final date = MerchantOrderAmountUtils.earningsDate(order) ??
      _parseDate(order.createdAt);
  return date?.hour;
}

String _formatHour(int hour) {
  if (hour == 0) return '12a';
  if (hour < 12) return '${hour}a';
  if (hour == 12) return '12p';
  return '${hour - 12}p';
}

String _weekdayLabel(int weekday) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[(weekday - 1) % 7];
}
