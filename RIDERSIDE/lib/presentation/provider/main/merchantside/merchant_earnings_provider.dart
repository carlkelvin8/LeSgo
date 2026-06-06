import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/merchant_order_amount_utils.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import 'merchant_orders_provider.dart';

class MerchantEarningEntry {
  final OrderDto order;
  final double amount;
  final DateTime? date;

  const MerchantEarningEntry({
    required this.order,
    required this.amount,
    this.date,
  });
}

class MerchantEarningsSummary {
  final double totalEarnings;
  final double pendingEarnings;
  final int completedOrders;
  final int pendingOrders;
  final double averageOrderValue;
  final List<MerchantEarningEntry> completedEntries;

  const MerchantEarningsSummary({
    this.totalEarnings = 0,
    this.pendingEarnings = 0,
    this.completedOrders = 0,
    this.pendingOrders = 0,
    this.averageOrderValue = 0,
    this.completedEntries = const [],
  });
}

final merchantEarningsPeriodProvider =
    StateProvider<MerchantEarningsPeriod>((ref) {
  return MerchantEarningsPeriod.month;
});

final merchantEarningsSummaryProvider =
    Provider<AsyncValue<MerchantEarningsSummary>>((ref) {
  final ordersAsync = ref.watch(merchantOrdersProvider);
  final period = ref.watch(merchantEarningsPeriodProvider);

  return ordersAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (orders) => AsyncValue.data(
      _buildSummary(orders, period),
    ),
  );
});

final merchantTodayEarningsProvider = Provider<AsyncValue<double>>((ref) {
  final ordersAsync = ref.watch(merchantOrdersProvider);

  return ordersAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (orders) {
      final todaySummary = _buildSummary(orders, MerchantEarningsPeriod.today);
      return AsyncValue.data(todaySummary.totalEarnings);
    },
  );
});

final merchantMonthEarningsProvider = Provider<AsyncValue<double>>((ref) {
  final ordersAsync = ref.watch(merchantOrdersProvider);

  return ordersAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (orders) {
      final monthSummary = _buildSummary(orders, MerchantEarningsPeriod.month);
      return AsyncValue.data(monthSummary.totalEarnings);
    },
  );
});

final merchantAllTimeEarningsProvider = Provider<AsyncValue<double>>((ref) {
  final ordersAsync = ref.watch(merchantOrdersProvider);

  return ordersAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (orders) {
      final allSummary = _buildSummary(orders, MerchantEarningsPeriod.all);
      return AsyncValue.data(allSummary.totalEarnings);
    },
  );
});

MerchantEarningsSummary _buildSummary(
  List<OrderDto> orders,
  MerchantEarningsPeriod period,
) {
  var totalEarnings = 0.0;
  var pendingEarnings = 0.0;
  var completedOrders = 0;
  var pendingOrders = 0;
  final completedEntries = <MerchantEarningEntry>[];

  for (final order in orders) {
    if (!MerchantOrderAmountUtils.isWithinPeriod(order, period)) continue;

    final amount = MerchantOrderAmountUtils.foodEarnings(order);
    if (amount <= 0) continue;

    if (MerchantOrderAmountUtils.isCompleted(order)) {
      totalEarnings += amount;
      completedOrders += 1;
      completedEntries.add(
        MerchantEarningEntry(
          order: order,
          amount: amount,
          date: MerchantOrderAmountUtils.earningsDate(order),
        ),
      );
    } else if (MerchantOrderAmountUtils.isPendingEarnings(order)) {
      pendingEarnings += amount;
      pendingOrders += 1;
    }
  }

  completedEntries.sort((a, b) {
    final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });

  final averageOrderValue =
      completedOrders > 0 ? totalEarnings / completedOrders : 0.0;

  return MerchantEarningsSummary(
    totalEarnings: totalEarnings,
    pendingEarnings: pendingEarnings,
    completedOrders: completedOrders,
    pendingOrders: pendingOrders,
    averageOrderValue: averageOrderValue,
    completedEntries: completedEntries,
  );
}

String formatMerchantPeso(double amount) => '₱${amount.toStringAsFixed(2)}';
