import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/daily_sales_summary_service.dart';
import '../../../../core/utils/merchant_order_amount_utils.dart';
import 'merchant_orders_provider.dart';

/// Provider that computes today's completed orders count and revenue.
final merchantDailySummaryProvider =
    FutureProvider.autoDispose<DailySalesSummaryData?>((ref) async {
  final shouldShow = await DailySalesSummaryService.shouldShowSummary();
  if (!shouldShow) return null;

  final ordersAsync = ref.watch(merchantOrdersProvider);
  final orders = ordersAsync.valueOrNull;
  if (orders == null || orders.isEmpty) return null;

  final now = DateTime.now();
  var completedToday = 0;
  var revenueToday = 0.0;

  for (final order in orders) {
    if (!MerchantOrderAmountUtils.isCompleted(order)) continue;
    final date = DateTime.tryParse(order.createdAt)?.toLocal();
    if (date == null) continue;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      completedToday++;
      revenueToday += MerchantOrderAmountUtils.foodEarnings(order);
    }
  }

  if (completedToday == 0) return null;

  return DailySalesSummaryService.buildSummary(
    completedOrdersToday: completedToday,
    revenueToday: revenueToday,
  );
});

/// State provider to control whether the banner is dismissed in-session.
final merchantDailySummaryDismissedProvider = StateProvider<bool>((ref) => false);
