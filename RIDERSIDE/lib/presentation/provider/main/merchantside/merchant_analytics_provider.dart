import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/merchant_order_amount_utils.dart';
import '../../../../data/data_source/dto/merchant/menu_item_dto.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import 'merchant_menu_provider.dart';
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

class MerchantCustomerInfo {
  final String name;
  final int orderCount;
  final double totalSpent;

  const MerchantCustomerInfo({
    required this.name,
    required this.orderCount,
    required this.totalSpent,
  });
}

class MerchantCategoryPerformance {
  final String categoryName;
  final int orderCount;
  final double revenue;
  final int itemCount;

  const MerchantCategoryPerformance({
    required this.categoryName,
    required this.orderCount,
    required this.revenue,
    required this.itemCount,
  });
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

  // Customer analytics
  final int newCustomerCount;
  final int returningCustomerCount;
  final List<MerchantCustomerInfo> topCustomers;
  final double avgCustomerLifetimeValue;

  // Product analytics
  final List<MerchantTopItem> leastSoldItems;
  final List<MerchantCategoryPerformance> categoryPerformance;

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
    this.newCustomerCount = 0,
    this.returningCustomerCount = 0,
    this.topCustomers = const [],
    this.avgCustomerLifetimeValue = 0,
    this.leastSoldItems = const [],
    this.categoryPerformance = const [],
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
  final menuAsync = ref.watch(merchantMenuProvider);

  final rating = reviewsAsync.maybeWhen(
    data: (dashboard) => dashboard.statistics.averageRating,
    orElse: () => profile?.rating ?? 0,
  );
  final totalReviews = reviewsAsync.maybeWhen(
    data: (dashboard) => dashboard.statistics.totalReviews,
    orElse: () => profile?.totalReviews ?? 0,
  );

  final menuItems = menuAsync.when(
    data: (menu) {
      if (menu == null) return <MenuItemDto>[];
      return menu.categories
          .where((cat) => cat.availableItems != null)
          .expand((cat) => cat.availableItems!)
          .toList();
    },
    loading: () => <MenuItemDto>[],
    error: (_, __) => <MenuItemDto>[],
  );

  return ordersAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (orders) => AsyncValue.data(
      _buildSummary(
        orders,
        period,
        menuItems: menuItems,
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
  List<MenuItemDto> menuItems = const [],
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

  // Customer tracking
  final customerMap = <int, MerchantCustomerInfo>{};
  // Track all customer order dates to determine new vs returning
  final allCustomerOrderDates = <int, List<DateTime>>{};
  final periodStartDate = _periodStartDate(period);

  for (final order in orders) {
    if (!_isOrderCreatedInPeriod(order, period)) continue;

    totalOrders += 1;
    _addToTrend(trendBuckets, order, period);

    // Track customer
    if (order.user != null) {
      final cid = order.user!.id;
      final spent = MerchantOrderAmountUtils.foodEarnings(order);
      final existing = customerMap[cid];
      if (existing == null) {
        customerMap[cid] = MerchantCustomerInfo(
          name: order.user!.name,
          orderCount: 1,
          totalSpent: spent,
        );
      } else {
        customerMap[cid] = MerchantCustomerInfo(
          name: existing.name,
          orderCount: existing.orderCount + 1,
          totalSpent: existing.totalSpent + spent,
        );
      }
    }

    // Track all dates for new vs returning detection
    if (order.user != null) {
      final date = _parseDate(order.createdAt);
      if (date != null) {
        allCustomerOrderDates
            .putIfAbsent(order.user!.id, () => [])
            .add(date);
      }
    }

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

  // New vs returning customers
  var newCount = 0;
  var returningCount = 0;
  for (final entry in allCustomerOrderDates.entries) {
    final dates = entry.value;
    // A customer is "returning" if they have an order BEFORE the period start
    final hadPriorOrder = dates.any((d) => periodStartDate != null && d.isBefore(periodStartDate));
    if (hadPriorOrder) {
      returningCount++;
    } else {
      newCount++;
    }
  }

  // Top customers (sorted by total spent)
  final topCustomersList = customerMap.values.toList()
    ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

  // Avg customer lifetime value
  final uniqueCustomerCount = customerMap.length;
  final avgLifetimeValue = uniqueCustomerCount > 0
      ? totalRevenue / uniqueCustomerCount
      : 0.0;

  // Peak hours
  final peakHours = <MerchantPeakHour>[];
  for (var hour = 0; hour < 24; hour++) {
    if (hourlyCounts[hour] > 0) {
      peakHours.add(MerchantPeakHour(hour: hour, orderCount: hourlyCounts[hour]));
    }
  }
  peakHours.sort((a, b) => b.orderCount.compareTo(a.orderCount));
  final topPeakHours = peakHours.take(5).toList();

  // Top items
  final topItems = itemMap.values.toList()
    ..sort((a, b) {
      final qty = b.quantitySold.compareTo(a.quantitySold);
      return qty != 0 ? qty : b.revenue.compareTo(a.revenue);
    });

  // Least sold items - items with > 0 sales, sorted ascending
  final leastSold = itemMap.values.toList()
    ..sort((a, b) {
      final qty = a.quantitySold.compareTo(b.quantitySold);
      return qty != 0 ? qty : a.revenue.compareTo(b.revenue);
    });

  // Category performance - build menuItemId -> categoryName lookup
  final itemCategoryMap = <int, String>{};
  for (final item in menuItems) {
    final catName = item.category?.name ?? 'Uncategorized';
    itemCategoryMap[item.id] = catName;
  }

  final categoryMap = <String, MerchantCategoryPerformance>{};
  for (final order in orders) {
    if (!_isOrderCreatedInPeriod(order, period)) continue;
    if (!MerchantOrderAmountUtils.isCompleted(order)) continue;

    final items = order.orderItems ?? [];
    // Track which categories this order touches (count per order, not per item)
    final categoriesInOrder = <String>{};
    for (final item in items) {
      final catName = item.menuItemId != null
          ? (itemCategoryMap[item.menuItemId] ?? 'Uncategorized')
          : 'Uncategorized';
      categoriesInOrder.add(catName);
      final lineRevenue = item.totalPrice ??
          ((item.unitPrice ?? 0) * item.quantity);
      final existing = categoryMap[catName];
      if (existing == null) {
        categoryMap[catName] = MerchantCategoryPerformance(
          categoryName: catName,
          orderCount: 0, // will increment below per-order
          revenue: lineRevenue,
          itemCount: item.quantity,
        );
      } else {
        categoryMap[catName] = MerchantCategoryPerformance(
          categoryName: existing.categoryName,
          orderCount: existing.orderCount, // don't increment here
          revenue: existing.revenue + lineRevenue,
          itemCount: existing.itemCount + item.quantity,
        );
      }
    }
    // Increment orderCount once per order per category
    for (final catName in categoriesInOrder) {
      final existing = categoryMap[catName]!;
      categoryMap[catName] = MerchantCategoryPerformance(
        categoryName: existing.categoryName,
        orderCount: existing.orderCount + 1,
        revenue: existing.revenue,
        itemCount: existing.itemCount,
      );
    }
  }

  final categoryPerformance = categoryMap.values.toList()
    ..sort((a, b) => b.revenue.compareTo(a.revenue));

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
    newCustomerCount: newCount,
    returningCustomerCount: returningCount,
    topCustomers: topCustomersList.take(5).toList(),
    avgCustomerLifetimeValue: avgLifetimeValue,
    leastSoldItems: leastSold.take(5).toList(),
    categoryPerformance: categoryPerformance,
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

DateTime? _periodStartDate(MerchantEarningsPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case MerchantEarningsPeriod.today:
      return DateTime(now.year, now.month, now.day);
    case MerchantEarningsPeriod.week:
      return DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
    case MerchantEarningsPeriod.month:
      return DateTime(now.year, now.month, 1);
    case MerchantEarningsPeriod.all:
      return DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 29));
  }
}
