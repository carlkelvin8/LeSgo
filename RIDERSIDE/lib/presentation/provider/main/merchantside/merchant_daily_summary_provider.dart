import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/daily_sales_summary_service.dart';
import '../../../../core/utils/merchant_order_amount_utils.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import 'merchant_orders_provider.dart';

/// Provider that computes today's completed orders count and revenue.
final merchantDailySummaryProvider =
    FutureProvider.autoDispose<DailySalesSummaryData?>((ref) async {
  final shouldShow = await DailySalesSummaryService.shouldShowSummary();
  if (!shouldShow) return null;

  final ordersAsync = ref.watch(merchantOrdersProvider);
  final orders = ordersAsync.valueOrNull;
  if (orders == null || orders.isEmpty) return null;

  return computeTodaySalesSummary(orders);
});

/// Today's completed orders and food revenue, or null if there are none.
///
/// Orders are attributed to the COMPLETION day (completed_at), like Analytics
/// and the Sales Report: an order placed 23:50 yesterday and delivered 00:20
/// today is today's sale.
DailySalesSummaryData? computeTodaySalesSummary(List<OrderDto> orders) {
  var completedToday = 0;
  var revenueToday = 0.0;

  for (final order in orders) {
    if (!MerchantOrderAmountUtils.isCompleted(order)) continue;
    if (!MerchantOrderAmountUtils.isWithinPeriod(
      order,
      MerchantEarningsPeriod.today,
    )) {
      continue;
    }
    completedToday++;
    revenueToday += MerchantOrderAmountUtils.foodEarnings(order);
  }

  if (completedToday == 0) return null;

  return DailySalesSummaryService.buildSummary(
    completedOrdersToday: completedToday,
    revenueToday: revenueToday,
  );
}

/// State provider to control whether the banner is dismissed in-session.
final merchantDailySummaryDismissedProvider = StateProvider<bool>((ref) => false);
