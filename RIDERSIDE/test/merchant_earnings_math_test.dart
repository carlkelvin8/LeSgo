// Merchant earnings math: Business Overview / analytics, daily summary and the
// order-detail amounts ("Credited to E-Wallet").
//
// Expected values are hand-computed. Money must match the backend formulas:
//   OrderSettlementService::merchantAmount   (what the store wallet is credited)
//   OrderWalletPaymentService::resolvePayableAmount
// both = SUM(COALESCE(actual_price, estimated_price) * quantity), where
// estimated_price is the per-unit price WITH size/flavor/add-on extras already
// included (MenuItemOptionsHelper::calculateUnitPrice).
//
// Timestamps are built the way Laravel serializes them: UTC ISO-8601 with `Z`.
// The app converts them with `.toLocal()`, i.e. it buckets by DEVICE time. For
// a merchant phone set to Asia/Manila that is PH time; the PH-specific group
// below is skipped when the test machine is not on UTC+8.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/utils/merchant_order_amount_utils.dart';
import 'package:lezgo_rider/core/utils/merchant_payment_utils.dart';
import 'package:lezgo_rider/data/data_source/dto/merchant/order_dto.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_analytics_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_daily_summary_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_menu_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_orders_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_profile_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_reviews_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── fixtures ────────────────────────────────────────────────────────────────

/// Local wall-clock time [daysAgo] days before today at [hour]:[minute].
DateTime _localDay(int daysAgo, int hour, [int minute = 0]) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - daysAgo, hour, minute);
}

/// Laravel-style UTC timestamp, e.g. `2026-11-09T15:50:00.000Z`.
String _iso(DateTime t) => t.toUtc().toIso8601String();

Map<String, dynamic> _item({
  required int id,
  int? menuItemId,
  required String name,
  required int qty,
  num? estimated,
  num? actual,
  Map<String, dynamic>? options,
}) =>
    {
      'id': id,
      'order_id': 1,
      'menu_item_id': menuItemId,
      'name': name,
      'quantity': qty,
      'estimated_price': estimated?.toString(),
      'actual_price': actual?.toString(),
      'selected_options': options ?? <dynamic>[],
    };

OrderDto _order({
  required int id,
  required String status,
  required DateTime createdAt,
  DateTime? completedAt,
  DateTime? cancelledAt,
  List<Map<String, dynamic>>? items,
  int? customerId,
  String paymentMethod = 'cash',
  String paymentStatus = 'pending',
  num? partnerShare,
  Map<String, dynamic>? meta,
  Map<String, dynamic>? fareBreakdown,
  num? totalFare,
}) {
  return OrderDto.fromJson({
    'id': id,
    'reference_number': 'REF-$id',
    'customer_id': customerId ?? 999,
    'partner_id': 7,
    'service_id': 2,
    'status': status,
    'pickup_address': 'Store',
    'dropoff_address': 'Home',
    'payment_method': paymentMethod,
    'payment_status': paymentStatus,
    'total_fare': totalFare?.toString(),
    'partner_share': partnerShare?.toString(),
    'meta': meta,
    'fare_breakdown': fareBreakdown,
    'created_at': _iso(createdAt),
    'updated_at': _iso(completedAt ?? cancelledAt ?? createdAt),
    'completed_at': completedAt == null ? null : _iso(completedAt),
    'cancelled_at': cancelledAt == null ? null : _iso(cancelledAt),
    if (customerId != null)
      'customer': {
        'id': customerId,
        'name': 'Customer $customerId',
        'email': 'c$customerId@example.test',
      },
    if (items != null) 'lesbuy_items': items,
  });
}

Future<MerchantAnalyticsSummary> _summarize(
  List<OrderDto> orders,
  MerchantEarningsPeriod period,
) async {
  final container = ProviderContainer(overrides: [
    merchantOrdersProvider.overrideWith((ref) async => orders),
    merchantProfileProvider.overrideWith((ref) async => null),
    merchantMenuProvider.overrideWith((ref) async => null),
    merchantReviewsDashboardProvider.overrideWith(
      (ref) => Future<MerchantReviewsDashboard>.error(StateError('offline')),
    ),
  ]);
  addTearDown(container.dispose);

  container.read(merchantAnalyticsPeriodProvider.notifier).state = period;
  container.listen(merchantAnalyticsSummaryProvider, (_, __) {});
  await container.read(merchantOrdersProvider.future);
  await Future<void>.delayed(Duration.zero);

  final summary = container.read(merchantAnalyticsSummaryProvider);
  expect(summary.hasValue, isTrue, reason: 'summary should be built');
  return summary.value!;
}

double _sumTrendRevenue(MerchantAnalyticsSummary s) =>
    s.trend.fold(0.0, (sum, p) => sum + p.revenue);

// Burger w/ Large (+20) and Cheese (+15): the server stores estimated_price as
// the full unit price 120 + 20 + 15 = 155.
const _burgerOptions = {
  'size': {'label': 'Large', 'price': 20},
  'addons': [
    {'label': 'Cheese', 'price': 15, 'quantity': 1},
  ],
};

void main() {
  // ─── line / subtotal math ─────────────────────────────────────────────────

  group('lineTotal / itemSubtotal (must equal backend merchantAmount)', () {
    OrderItemDto item(Map<String, dynamic> json) => OrderItemDto.fromJson(json);

    test('plain item: estimated_price x quantity', () {
      expect(
        MerchantOrderAmountUtils.lineTotal(
          item(_item(id: 1, name: 'Burger', qty: 2, estimated: 120)),
        ),
        240.0,
      );
    });

    test('add-ons are already inside estimated_price and are NOT added twice',
        () {
      // 155 x 2 = 310. (Old code: (155 + 35) x 2 = 380.)
      expect(
        MerchantOrderAmountUtils.lineTotal(item(_item(
          id: 1,
          name: 'Burger',
          qty: 2,
          estimated: 155,
          options: _burgerOptions,
        ))),
        310.0,
      );
    });

    test('actual_price is a per-unit price and is multiplied by quantity', () {
      // COALESCE(55, 50) x 3 = 165. (Old code returned 55.)
      expect(
        MerchantOrderAmountUtils.lineTotal(item(_item(
          id: 1,
          name: 'Milk Tea',
          qty: 3,
          estimated: 50,
          actual: 55,
        ))),
        165.0,
      );
    });

    test('actual_price of 0 falls back to estimated_price', () {
      expect(
        MerchantOrderAmountUtils.lineTotal(item(
          _item(id: 1, name: 'Fries', qty: 2, estimated: 65, actual: 0),
        )),
        130.0,
      );
    });

    test('no prices at all -> 0', () {
      expect(
        MerchantOrderAmountUtils.lineTotal(
          item(_item(id: 1, name: 'Mystery', qty: 4)),
        ),
        0.0,
      );
    });

    test('itemSubtotal sums lines and ignores delivery fare', () {
      final order = _order(
        id: 1,
        status: 'completed',
        createdAt: _localDay(1, 12),
        totalFare: 80,
        items: [
          _item(id: 1, name: 'Burger', qty: 2, estimated: 120), // 240
          _item(id: 2, name: 'Fries', qty: 1, estimated: 65), // 65
        ],
      );
      expect(MerchantOrderAmountUtils.itemSubtotal(order), 305.0);
      expect(MerchantOrderAmountUtils.foodEarnings(order), 305.0);
    });
  });

  // ─── foodEarnings fallback chain ──────────────────────────────────────────

  group('foodEarnings fallback: items -> partnerShare -> meta -> fareBreakdown',
      () {
    final created = _localDay(1, 12);

    test('items win over every other field', () {
      final order = _order(
        id: 1,
        status: 'completed',
        createdAt: created,
        items: [_item(id: 1, name: 'Burger', qty: 1, estimated: 120)],
        partnerShare: 999,
        meta: {'subtotal': 888, 'grand_total': 968},
        fareBreakdown: {'subtotal': 777},
      );
      expect(MerchantOrderAmountUtils.foodEarnings(order), 120.0);
    });

    test('items present but all zero-priced -> partnerShare', () {
      final order = _order(
        id: 1,
        status: 'completed',
        createdAt: created,
        items: [_item(id: 1, name: 'Burger', qty: 1, estimated: 0)],
        partnerShare: 150,
        meta: {'subtotal': 300},
        fareBreakdown: {'subtotal': 200},
      );
      expect(MerchantOrderAmountUtils.foodEarnings(order), 150.0);
    });

    test('no items -> partnerShare', () {
      final order = _order(
        id: 1,
        status: 'completed',
        createdAt: created,
        partnerShare: 150,
        meta: {'subtotal': 300},
        fareBreakdown: {'subtotal': 200},
      );
      expect(MerchantOrderAmountUtils.foodEarnings(order), 150.0);
    });

    test('no partnerShare -> meta order value (subtotal, not grand_total)', () {
      final order = _order(
        id: 1,
        status: 'completed',
        createdAt: created,
        partnerShare: 0,
        meta: {'subtotal': 300, 'delivery_fee': 80, 'grand_total': 380},
        fareBreakdown: {'subtotal': 200},
      );
      expect(MerchantOrderAmountUtils.foodEarnings(order), 300.0);
    });

    test('meta.order_value is preferred over meta.subtotal', () {
      final order = _order(
        id: 1,
        status: 'completed',
        createdAt: created,
        meta: {'order_value': 310, 'subtotal': 300},
      );
      expect(MerchantOrderAmountUtils.foodEarnings(order), 310.0);
    });

    test('no meta value -> fare_breakdown subtotal', () {
      final order = _order(
        id: 1,
        status: 'completed',
        createdAt: created,
        fareBreakdown: {'subtotal': 200},
      );
      expect(MerchantOrderAmountUtils.foodEarnings(order), 200.0);
    });

    test('meta with only grand_total (includes delivery) is NOT food value',
        () {
      final withBreakdown = _order(
        id: 1,
        status: 'completed',
        createdAt: created,
        meta: {'grand_total': 380, 'delivery_fee': 80},
        fareBreakdown: {'subtotal': 300},
      );
      expect(withBreakdown.metaOrderValue, isNull);
      expect(MerchantOrderAmountUtils.foodEarnings(withBreakdown), 300.0);

      final onlyGrandTotal = _order(
        id: 2,
        status: 'completed',
        createdAt: created,
        meta: {'grand_total': 380},
      );
      expect(MerchantOrderAmountUtils.foodEarnings(onlyGrandTotal), 0.0);
    });

    test('nothing at all -> 0', () {
      final order =
          _order(id: 1, status: 'completed', createdAt: created, totalFare: 80);
      expect(MerchantOrderAmountUtils.foodEarnings(order), 0.0);
    });
  });

  // ─── "Credited to E-Wallet" gating ────────────────────────────────────────

  group('creditsMerchantWallet (shows "Credited to E-Wallet")', () {
    test('online methods that are paid credit the store wallet', () {
      for (final m in ['wallet', 'gcash', 'maya', 'card', 'xendit', 'GCash']) {
        expect(MerchantPaymentUtils.creditsMerchantWallet(m, 'paid'), isTrue,
            reason: m);
      }
    });

    test('cash never credits the wallet, even when marked paid', () {
      expect(MerchantPaymentUtils.creditsMerchantWallet('cash', 'paid'),
          isFalse);
      expect(MerchantPaymentUtils.creditsMerchantWallet(null, 'paid'), isFalse);
      expect(MerchantPaymentUtils.creditsMerchantWallet('', 'paid'), isFalse);
    });

    test('online but not paid does not show the credit', () {
      // Only 'paid' counts (backend OrderSettlementService::isOnlinePaid);
      // 'completed' is not a payment status the backend credits on.
      for (final s in ['pending', 'failed', 'refunded', 'completed', '', null]) {
        expect(MerchantPaymentUtils.creditsMerchantWallet('gcash', s), isFalse,
            reason: '$s');
      }
    });

    test('credited amount equals backend merchantAmount for the order', () {
      // Backend: SUM(COALESCE(actual, estimated) * qty)
      //   = 155*2 + 55*3 + 65*1 = 310 + 165 + 65 = 540
      final order = _order(
        id: 1,
        status: 'completed',
        createdAt: _localDay(1, 12),
        completedAt: _localDay(1, 12, 30),
        paymentMethod: 'wallet',
        paymentStatus: 'paid',
        totalFare: 80,
        items: [
          _item(
              id: 1,
              name: 'Burger',
              qty: 2,
              estimated: 155,
              options: _burgerOptions),
          _item(id: 2, name: 'Milk Tea', qty: 3, estimated: 50, actual: 55),
          _item(id: 3, name: 'Fries', qty: 1, estimated: 65),
        ],
      );
      expect(
        MerchantPaymentUtils.creditsMerchantWallet(
            order.paymentMethod, order.paymentStatus),
        isTrue,
      );
      expect(MerchantOrderAmountUtils.foodEarnings(order), 540.0);
    });
  });

  // ─── analytics aggregation ────────────────────────────────────────────────

  group('merchantAnalyticsSummaryProvider (week)', () {
    late List<OrderDto> orders;

    setUp(() {
      orders = [
        // A: completed, 1 day ago. 2x120 + 1x65 = 305. Platform fields ignored.
        _order(
          id: 1,
          status: 'completed',
          createdAt: _localDay(1, 12),
          completedAt: _localDay(1, 12, 40),
          customerId: 100,
          paymentMethod: 'wallet',
          paymentStatus: 'paid',
          totalFare: 80,
          partnerShare: 250,
          meta: {'subtotal': 999},
          items: [
            _item(id: 1, menuItemId: 10, name: 'Burger', qty: 2, estimated: 120),
            _item(id: 2, menuItemId: 11, name: 'Fries', qty: 1, estimated: 65),
          ],
        ),
        // B: completed, 2 days ago. 1x155 (with add-ons) + 3x55 = 320.
        _order(
          id: 2,
          status: 'completed',
          createdAt: _localDay(2, 18),
          completedAt: _localDay(2, 18, 30),
          customerId: 101,
          items: [
            _item(
                id: 3,
                menuItemId: 10,
                name: 'Burger',
                qty: 1,
                estimated: 155,
                options: _burgerOptions),
            _item(
                id: 4,
                menuItemId: 12,
                name: 'Milk Tea',
                qty: 3,
                estimated: 50,
                actual: 55),
          ],
        ),
        // C: cancelled, 1 day ago, worth 600. Must not count as revenue.
        _order(
          id: 3,
          status: 'cancelled',
          createdAt: _localDay(1, 9),
          customerId: 101,
          items: [
            _item(id: 5, menuItemId: 10, name: 'Burger', qty: 5, estimated: 120),
          ],
        ),
        // D: pending, 1 day ago.
        _order(
          id: 4,
          status: 'pending',
          createdAt: _localDay(1, 20),
          items: [
            _item(id: 6, menuItemId: 11, name: 'Fries', qty: 10, estimated: 65),
          ],
        ),
        // E: in progress, 3 days ago.
        _order(
          id: 5,
          status: 'picked_up',
          createdAt: _localDay(3, 10),
          partnerShare: 400,
        ),
        // F: completed 10 days ago -> outside the week entirely.
        _order(
          id: 6,
          status: 'completed',
          createdAt: _localDay(10, 12),
          completedAt: _localDay(10, 12, 30),
          items: [
            _item(id: 7, menuItemId: 10, name: 'Burger', qty: 9, estimated: 120),
          ],
        ),
        // G: cancelled 4 days ago by customer 102 (never completed anything).
        _order(
          id: 7,
          status: 'cancelled',
          createdAt: _localDay(4, 8),
          cancelledAt: _localDay(4, 8, 5),
          customerId: 102,
        ),
        // H: completed 3 days ago, no items -> partnerShare 150.
        _order(
          id: 8,
          status: 'completed',
          createdAt: _localDay(3, 13),
          completedAt: _localDay(3, 13, 30),
          partnerShare: 150,
        ),
      ];
    });

    test('counts, revenue (completed only), rate and average', () async {
      final s = await _summarize(orders, MerchantEarningsPeriod.week);

      expect(s.totalOrders, 7); // A B C D E G H
      expect(s.completedOrders, 3); // A B H
      expect(s.cancelledOrders, 2); // C G
      expect(s.activeOrders, 2); // D E
      // 305 + 320 + 150. No delivery fare, no cancelled/pending/in-progress.
      expect(s.totalRevenue, closeTo(775, 1e-9));
      expect(s.averageOrderValue, closeTo(775 / 3, 1e-9)); // 258.33
      expect(s.cancellationRate, closeTo(40, 1e-9)); // 2 / (3 + 2)
    });

    test('top items ranked by quantity, then revenue', () async {
      final s = await _summarize(orders, MerchantEarningsPeriod.week);
      final rows =
          s.topItems.map((i) => [i.name, i.quantitySold, i.revenue]).toList();

      expect(rows, [
        ['Burger', 3, 395.0], // A 2x120=240 + B 1x155=155
        ['Milk Tea', 3, 165.0], // B 3x55
        ['Order #REF-8', 1, 150.0], // H, no item rows
        ['Fries', 1, 65.0], // A only; pending D excluded
      ]);
      // Every peso of revenue is attributed to exactly one top item.
      expect(
        s.topItems.fold<double>(0, (sum, i) => sum + i.revenue),
        closeTo(s.totalRevenue, 1e-9),
      );
    });

    test('trend buckets by attributed day and sums to total revenue', () async {
      final s = await _summarize(orders, MerchantEarningsPeriod.week);
      expect(s.trend, hasLength(7));

      final counts = s.trend.map((p) => p.orderCount).toList();
      final revenue = s.trend.map((p) => p.revenue).toList();
      // index = 6 - daysAgo
      expect(counts, [0, 0, 1, 2, 1, 3, 0]);
      expect(revenue, [0, 0, 0, 150, 320, 305, 0]);
      expect(_sumTrendRevenue(s), closeTo(s.totalRevenue, 1e-9));
    });

    test('top customers only count money from completed orders', () async {
      final s = await _summarize(orders, MerchantEarningsPeriod.week);
      final rows = s.topCustomers
          .map((c) => [c.name, c.orderCount, c.totalSpent])
          .toList();
      // 101 placed B (320, completed) and C (600, cancelled).
      // 102 only cancelled G.
      expect(rows, [
        ['Customer 101', 2, 320.0],
        ['Customer 100', 1, 305.0],
        ['Customer 102', 1, 0.0],
      ]);
    });

    test('avg customer value divides by customers with a completed order',
        () async {
      final s = await _summarize(orders, MerchantEarningsPeriod.week);
      // Revenue 775 (incl. H, which has no customer) / {100, 101} = 387.5.
      // 102 (only a cancelled order) must not dilute it (old: 775 / 3).
      expect(s.avgCustomerLifetimeValue, closeTo(387.5, 1e-9));
    });

    test('category performance without a menu = item lines only', () async {
      final s = await _summarize(orders, MerchantEarningsPeriod.week);
      expect(s.categoryPerformance, hasLength(1));
      final c = s.categoryPerformance.single;
      expect(c.categoryName, 'Uncategorized');
      expect(c.orderCount, 2); // A, B (H has no item rows)
      expect(c.itemCount, 7); // 2 + 1 + 1 + 3
      expect(c.revenue, closeTo(625, 1e-9)); // 305 + 320
    });
  });

  group('divide-by-zero / degenerate inputs', () {
    test('no orders -> all zero, no NaN', () async {
      final s = await _summarize(const [], MerchantEarningsPeriod.week);
      expect(s.totalOrders, 0);
      expect(s.totalRevenue, 0);
      expect(s.averageOrderValue, 0);
      expect(s.cancellationRate, 0);
      expect(s.avgCustomerLifetimeValue, 0);
      expect(s.trend.every((p) => p.orderCount == 0 && p.revenue == 0), isTrue);
    });

    test('only cancelled -> rate 100, average 0', () async {
      final s = await _summarize([
        _order(id: 1, status: 'cancelled', createdAt: _localDay(1, 10)),
        _order(id: 2, status: 'cancelled', createdAt: _localDay(2, 10)),
      ], MerchantEarningsPeriod.week);
      expect(s.cancellationRate, 100);
      expect(s.averageOrderValue, 0);
      expect(s.averageOrderValue.isNaN, isFalse);
    });

    test('only active orders -> rate 0 (no finished orders), average 0',
        () async {
      final s = await _summarize([
        _order(
          id: 1,
          status: 'pending',
          createdAt: _localDay(1, 10),
          partnerShare: 100,
        ),
      ], MerchantEarningsPeriod.week);
      expect(s.activeOrders, 1);
      expect(s.cancellationRate, 0);
      expect(s.averageOrderValue, 0);
      expect(s.totalRevenue, 0);
    });

    test('completed with no amount anywhere: counted, adds 0 revenue',
        () async {
      final s = await _summarize([
        _order(
          id: 1,
          status: 'completed',
          createdAt: _localDay(1, 10),
          completedAt: _localDay(1, 11),
        ),
        _order(
          id: 2,
          status: 'completed',
          createdAt: _localDay(1, 12),
          completedAt: _localDay(1, 13),
          partnerShare: 100,
        ),
      ], MerchantEarningsPeriod.week);
      expect(s.completedOrders, 2);
      expect(s.totalRevenue, 100);
      expect(s.averageOrderValue, 50); // revenue / completed
    });
  });

  // ─── day boundary (device local time) ─────────────────────────────────────

  group('day bucketing across local midnight', () {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final lateYesterday = midnight.subtract(const Duration(minutes: 10));
    final earlyToday = midnight.add(const Duration(minutes: 10));

    List<OrderDto> nearMidnight() => [
          // Created 23:50 yesterday, completed 00:20 today.
          _order(
            id: 1,
            status: 'completed',
            createdAt: lateYesterday,
            completedAt: midnight.add(const Duration(minutes: 20)),
            items: [_item(id: 1, name: 'Burger', qty: 1, estimated: 120)],
          ),
          // Created 00:10 today.
          _order(
            id: 2,
            status: 'completed',
            createdAt: earlyToday,
            completedAt: earlyToday.add(const Duration(minutes: 5)),
            items: [_item(id: 2, name: 'Fries', qty: 2, estimated: 65)],
          ),
        ];

    // Completed 23:30 yesterday (stays on yesterday).
    OrderDto doneYesterday() => _order(
          id: 3,
          status: 'completed',
          createdAt: midnight.subtract(const Duration(minutes: 50)),
          completedAt: midnight.subtract(const Duration(minutes: 30)),
          partnerShare: 40,
        );

    test('week: 23:50 -> 00:20 order lands on the completion day (today)',
        () async {
      final s = await _summarize(
          [...nearMidnight(), doneYesterday()], MerchantEarningsPeriod.week);
      expect(s.trend[5].orderCount, 1); // only doneYesterday
      expect(s.trend[5].revenue, 40);
      expect(s.trend[6].orderCount, 2);
      expect(s.trend[6].revenue, 250); // 120 + 130
      expect(s.totalRevenue, 290);
    });

    test('Analytics today: counts the 23:50 order completed at 00:20',
        () async {
      final s = await _summarize(
          [...nearMidnight(), doneYesterday()], MerchantEarningsPeriod.today);
      expect(s.totalOrders, 2);
      expect(s.completedOrders, 2);
      expect(s.totalRevenue, 250);
      expect(s.averageOrderValue, 125);
      expect(s.topItems.map((i) => i.name), ['Fries', 'Burger']);
      expect(s.trend, hasLength(24));
      expect(s.trend[0].orderCount, 2); // both completed in the 12 AM hour
      expect(s.trend[0].revenue, 250);
      expect(s.trend[23].orderCount, 0);
    });

    test('daily summary banner: same completion-day rule', () {
      final data =
          computeTodaySalesSummary([...nearMidnight(), doneYesterday()]);
      expect(data, isNotNull);
      expect(data!.completedOrders, 2);
      expect(data.revenue, 250);
    });

    test('Sales Report range: same completion-day rule', () {
      final orders = [...nearMidnight(), doneYesterday()];
      final yesterday = midnight.subtract(const Duration(days: 1));
      bool inRange(OrderDto o, DateTime from, DateTime to) =>
          MerchantOrderAmountUtils.isWithinDateRange(o, from, to);

      final todayRows = orders.where((o) => inRange(o, now, now)).toList();
      expect(todayRows.map((o) => o.id), [1, 2]);
      expect(
        todayRows.fold<double>(
            0, (s, o) => s + MerchantOrderAmountUtils.foodEarnings(o)),
        250,
      );
      final yesterdayRows =
          orders.where((o) => inRange(o, yesterday, yesterday)).toList();
      expect(yesterdayRows.map((o) => o.id), [3]);
      // End of range is inclusive through 23:59:59.999.
      final lateOrder = _order(
        id: 9,
        status: 'completed',
        createdAt: midnight.subtract(const Duration(hours: 1)),
        completedAt: midnight.subtract(const Duration(milliseconds: 1)),
        partnerShare: 10,
      );
      expect(inRange(lateOrder, yesterday, yesterday), isTrue);
      expect(inRange(lateOrder, now, now), isFalse);
    });

    test('"orders received today" card still counts by created_at', () async {
      final container = ProviderContainer(overrides: [
        merchantOrdersProvider
            .overrideWith((ref) async => [...nearMidnight(), doneYesterday()]),
      ]);
      addTearDown(container.dispose);
      container.listen(merchantTodayOrderCountProvider, (_, __) {});
      await container.read(merchantOrdersProvider.future);
      // Only order 2 was placed today.
      expect(container.read(merchantTodayOrderCountProvider).value, 1);
    });

    test('earningsDate: completed_at, then updated_at, then created_at', () {
      final order = nearMidnight().first;
      expect(MerchantOrderAmountUtils.earningsDate(order),
          midnight.add(const Duration(minutes: 20)));

      final noCompletedAt = OrderDto.fromJson({
        'id': 1,
        'customer_id': 1,
        'service_id': 2,
        'status': 'completed',
        'created_at': _iso(lateYesterday),
        'updated_at': _iso(earlyToday),
      });
      expect(MerchantOrderAmountUtils.earningsDate(noCompletedAt), earlyToday);
    });

    test('cancelled orders count on cancelled_at (fallback created_at)',
        () async {
      final orders = [
        // Placed 23:50 yesterday, cancelled 00:05 today -> today.
        _order(
          id: 1,
          status: 'cancelled',
          createdAt: lateYesterday,
          cancelledAt: midnight.add(const Duration(minutes: 5)),
        ),
        // No cancelled_at: placed 23:50 yesterday -> yesterday.
        _order(id: 2, status: 'cancelled', createdAt: lateYesterday),
      ];
      expect(MerchantOrderAmountUtils.earningsDate(orders[0]),
          midnight.add(const Duration(minutes: 5)));
      expect(MerchantOrderAmountUtils.earningsDate(orders[1]), lateYesterday);

      final today = await _summarize(orders, MerchantEarningsPeriod.today);
      expect(today.cancelledOrders, 1);
      expect(today.cancellationRate, 100);
      final week = await _summarize(orders, MerchantEarningsPeriod.week);
      expect(week.cancelledOrders, 2);
      expect(week.trend[5].orderCount, 1);
      expect(week.trend[6].orderCount, 1);
    });

    test('all-time chart: orders older than 30 days stay out of bucket 0',
        () async {
      final s = await _summarize([
        _order(
          id: 1,
          status: 'completed',
          createdAt: _localDay(100, 12),
          completedAt: _localDay(100, 13),
          partnerShare: 500,
        ),
        _order(
          id: 2,
          status: 'completed',
          createdAt: _localDay(29, 12),
          completedAt: _localDay(29, 13),
          partnerShare: 40,
        ),
        _order(
          id: 3,
          status: 'completed',
          createdAt: _localDay(0, 0, 1),
          completedAt: _localDay(0, 0, 2),
          partnerShare: 60,
        ),
      ], MerchantEarningsPeriod.all);
      // Totals still include all history...
      expect(s.totalOrders, 3);
      expect(s.totalRevenue, 600);
      // ...but the 30-day chart only shows the last 30 days.
      expect(s.trend, hasLength(30));
      expect(s.trend[0].orderCount, 1);
      expect(s.trend[0].revenue, 40);
      expect(s.trend[29].revenue, 60);
      expect(_sumTrendRevenue(s), 100);
    });
  });

  group('Asia/Manila wall clock (device on UTC+8)', () {
    final onManila =
        DateTime.now().timeZoneOffset == const Duration(hours: 8);

    test(
      'UTC timestamps around 16:00Z split on Manila midnight',
      () async {
        // Manila "today" computed from UTC, independent of device settings.
        final manilaNow = DateTime.now().toUtc().add(const Duration(hours: 8));
        final manilaMidnightUtc =
            DateTime.utc(manilaNow.year, manilaNow.month, manilaNow.day)
                .subtract(const Duration(hours: 8)); // e.g. 16:00Z yesterday
        String at(int minutesFromMidnight) => manilaMidnightUtc
            .add(Duration(minutes: minutesFromMidnight))
            .toIso8601String();
        OrderDto completed(int id, int createdMin, int completedMin, int pesos) =>
            OrderDto.fromJson({
              'id': id,
              'customer_id': 1,
              'service_id': 2,
              'status': 'completed',
              'created_at': at(createdMin),
              'updated_at': at(completedMin),
              'completed_at': at(completedMin),
              'partner_share': '$pesos',
            });
        final orders = [
          // 23:40 -> 23:55 Manila yesterday (15:40Z -> 15:55Z).
          completed(1, -20, -5, 100),
          // 23:50 Manila yesterday -> 00:20 Manila today (16:20Z).
          completed(2, -10, 20, 200),
        ];
        expect(orders.first.createdAt, endsWith('Z'));

        final today = await _summarize(orders, MerchantEarningsPeriod.today);
        expect(today.totalOrders, 1);
        expect(today.totalRevenue, 200);
        expect(today.trend[0].orderCount, 1); // 12 AM Manila, not 4 PM UTC
        expect(computeTodaySalesSummary(orders)!.revenue, 200);

        final week = await _summarize(orders, MerchantEarningsPeriod.week);
        expect(week.trend[5].revenue, 100);
        expect(week.trend[6].revenue, 200);
      },
      skip: onManila ? false : 'device timezone is not UTC+8',
    );
  });

  // ─── daily summary banner ─────────────────────────────────────────────────

  group('merchantDailySummaryProvider', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('today = completed orders COMPLETED today; revenue = food only',
        () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final orders = [
        _order(
          id: 1,
          status: 'completed',
          createdAt: midnight.add(const Duration(minutes: 1)),
          completedAt: midnight.add(const Duration(minutes: 30)),
          totalFare: 80,
          items: [
            _item(
                id: 1,
                name: 'Burger',
                qty: 2,
                estimated: 155,
                options: _burgerOptions),
          ], // 310
        ),
        _order(
          id: 2,
          status: 'completed',
          createdAt: midnight.add(const Duration(minutes: 2)),
          completedAt: midnight.add(const Duration(minutes: 40)),
          partnerShare: 90,
        ),
        _order(
          id: 3,
          status: 'cancelled',
          createdAt: midnight.add(const Duration(minutes: 3)),
          partnerShare: 500,
        ),
        _order(
          id: 4,
          status: 'completed',
          createdAt: midnight.subtract(const Duration(minutes: 10)),
          completedAt: midnight.add(const Duration(minutes: 5)),
          partnerShare: 700,
        ),
        // Completed yesterday -> excluded.
        _order(
          id: 5,
          status: 'completed',
          createdAt: midnight.subtract(const Duration(hours: 2)),
          completedAt: midnight.subtract(const Duration(hours: 1)),
          partnerShare: 1000,
        ),
      ];

      // Pure counting rule (independent of the 8 PM gate):
      // 310 + 90 + 700 (placed 23:50 yesterday, completed 00:05 today).
      final pure = computeTodaySalesSummary(orders);
      expect(pure!.completedOrders, 3);
      expect(pure.revenue, 1100);

      final container = ProviderContainer(overrides: [
        merchantOrdersProvider.overrideWith((ref) async => orders),
      ]);
      addTearDown(container.dispose);
      container.listen(merchantDailySummaryProvider, (_, __) {});
      await container.read(merchantOrdersProvider.future);
      final data = await container.read(merchantDailySummaryProvider.future);

      if (now.hour < 20) {
        // Banner is only offered after 8 PM.
        expect(data, isNull);
      } else {
        expect(data, isNotNull);
        expect(data!.completedOrders, 3);
        expect(data.revenue, 1100);
      }
    });
  });
}
