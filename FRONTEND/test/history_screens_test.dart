import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/dto/order/order_dto.dart';
import 'package:lesgo/data/data_source/dto/order/orders_response_dto.dart';
import 'package:lesgo/data/data_source/dto/wallet/wallet_dto.dart';
import 'package:lesgo/data/data_source/order_remote_datasource.dart';
import 'package:lesgo/data/data_source/wallet_remote_datasource.dart';
import 'package:lesgo/presentation/provider/main/orders/order_history_provider.dart';
import 'package:lesgo/presentation/screens/main/orders/order_history_screen.dart';
import 'package:lesgo/presentation/screens/main/transactions_screen.dart';

String _iso(DateTime d) => d.toUtc().toIso8601String();

OrderDto _order(
  int id,
  String status, {
  int service = 3,
  String payment = 'paid',
  String method = 'cash',
  double fare = 100,
  required DateTime at,
  String pickup = 'Claveria, Cagayan',
  String dropoff = 'Belado Avenue, Centro III',
  List<Map<String, dynamic>> items = const [],
}) => OrderDto.fromJson({
  'id': id,
  'customer_id': 1,
  'service_id': service,
  'pickup_address': pickup,
  'pickup_lat': 18.6,
  'pickup_lng': 121.0,
  'pickup_contact_name': 'a',
  'pickup_contact_phone': '1',
  'dropoff_address': dropoff,
  'dropoff_lat': 18.61,
  'dropoff_lng': 121.01,
  'dropoff_contact_name': 'b',
  'dropoff_contact_phone': '2',
  'discount_amount': 0,
  'status': status,
  'estimated_distance_m': 1000,
  'estimated_fare': fare,
  'payment_method': method,
  'payment_status': payment,
  'created_at': _iso(at),
  'lesbuy_items': items,
});

final _now = DateTime.now();
// Fixed local noon, so day headings don't depend on the time the tests run.
final _today = DateTime(_now.year, _now.month, _now.day, 12);
final _yesterday = _today.subtract(const Duration(days: 1));

List<OrderDto> _sample() => [
  _order(
    21,
    'completed',
    service: 3,
    fare: 233,
    at: _today,
    items: [
      {
        'id': 1,
        'order_id': 21,
        'menu_item_id': 2,
        'name': '1-pc Chickenjoy',
        'quantity': 2,
        'estimated_price': '89.00',
      },
      {
        'id': 2,
        'order_id': 21,
        'menu_item_id': 3,
        'name': 'Spaghetti',
        'quantity': 1,
        'estimated_price': '60.00',
      },
    ],
  ),
  _order(
    20,
    'cancelled',
    service: 2,
    fare: 60,
    payment: 'refunded',
    at: _yesterday,
  ),
  _order(
    19,
    'in_transit',
    service: 1,
    fare: 75,
    at: _today.subtract(const Duration(days: 2)),
  ),
];

class _FakeHistory extends OrderHistoryNotifier {
  _FakeHistory(List<OrderDto> orders) {
    state = OrderHistoryState(orders: orders, hasMore: false);
  }
  @override
  Future<void> loadOrders({bool refresh = false}) async {}
}

class _Orders implements OrderRemoteDataSource {
  _Orders(this.orders);
  final List<OrderDto> orders;
  @override
  Future<OrdersResponseDto> getOrders({
    String? status,
    String? paymentStatus,
    int? serviceId,
    int perPage = 20,
    int page = 1,
  }) async => OrdersResponseDto(success: true, data: orders);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Wallet implements WalletRemoteDataSource {
  @override
  Future<List<WalletTransactionDto>> getMyTransactions({String? type}) async =>
      [
        WalletTransactionDto(
          id: 1,
          walletId: 1,
          type: 'credit',
          amount: 1000,
          description: 'Top-up',
          createdAt: _iso(_today),
        ),
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _size(WidgetTester tester, double w, double scale) async {
  tester.view.physicalSize = Size(w, 900);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

void main() {
  group('OrderHistoryScreen', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderHistoryProvider.overrideWith((ref) => _FakeHistory(_sample())),
          ],
          child: const MaterialApp(home: OrderHistoryScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('shows summary, month heading and rich cards', (tester) async {
      await _size(tester, 390, 1.0);
      await pump(tester);

      expect(find.text('THIS MONTH'), findsWidgets);
      // No summary numbers and no order numbers on the cards.
      expect(find.text('Spent'), findsNothing);
      expect(find.textContaining('#21'), findsNothing);
      expect(find.text('1-pc Chickenjoy ×2 · +1 more'), findsOneWidget);
      expect(
        find.text('Order again'),
        findsOneWidget,
      ); // only on the completed one
      expect(find.text('Completed'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search narrows the list and can be cleared', (tester) async {
      await _size(tester, 390, 1.0);
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'chickenjoy');
      await tester.pump();
      expect(find.text('1-pc Chickenjoy ×2 · +1 more'), findsOneWidget);
      expect(find.text('Claveria, Cagayan'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz-nothing');
      await tester.pump();
      expect(find.text('No matching orders'), findsOneWidget);

      await tester.tap(find.text('Clear search & service'));
      await tester.pump();
      expect(find.text('Claveria, Cagayan'), findsWidgets);
    });

    testWidgets('service chip filters locally', (tester) async {
      await _size(tester, 390, 1.0);
      await pump(tester);

      final filters = find.byType(TabBar);
      expect(filters, findsNWidgets(2));
      expect(
        tester
            .widgetList<Tab>(
              find.descendant(of: filters, matching: find.byType(Tab)),
            )
            .every((tab) => tab.icon == null && tab.child == null),
        isTrue,
      );
      final controller = tester.widget<TabBar>(filters.last).controller!;
      await tester.tap(
        find.descendant(of: filters.last, matching: find.text('LesRide')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.animation!.value, allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();
      expect(find.text('Claveria, Cagayan'), findsWidgets);
      expect(find.text('1-pc Chickenjoy ×2 · +1 more'), findsNothing);
    });

    for (final c in [(320.0, 1.0), (320.0, 2.0)]) {
      testWidgets('no overflow at ${c.$1}px / ${c.$2}x text', (tester) async {
        await _size(tester, c.$1, c.$2);
        await pump(tester);
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView).last, const Offset(0, -600));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('TransactionsScreen', () {
    setUp(() {
      getIt.registerSingleton<OrderRemoteDataSource>(_Orders(_sample()));
      getIt.registerSingleton<WalletRemoteDataSource>(_Wallet());
    });
    tearDown(getIt.reset);

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: TransactionsScreen())),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('month summary, day headings and compact rows', (tester) async {
      await _size(tester, 390, 1.0);
      await pump(tester);

      expect(find.textContaining('Spent in'), findsNothing); // no summary card
      expect(find.textContaining('Order #'), findsNothing); // no order numbers
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('Top-up'), findsOneWidget);
      expect(find.text('+₱1,000.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('type chips filter and the filter sheet opens', (tester) async {
      await _size(tester, 390, 1.0);
      await pump(tester);

      await tester.tap(find.text('LesPay').first);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Top-up'), findsOneWidget);
      expect(find.text('LesEat'), findsNothing);

      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Reset'), findsOneWidget);
      expect(find.textContaining('Show '), findsOneWidget);
    });

    for (final c in [(320.0, 1.0), (320.0, 2.0)]) {
      testWidgets('no overflow at ${c.$1}px / ${c.$2}x text', (tester) async {
        await _size(tester, c.$1, c.$2);
        await pump(tester);
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView).last, const Offset(0, -500));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
