import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/data/data_source/dto/merchant/order_dto.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_orders_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_menu_image_lookup.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_prep_timer_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_orders_view.dart';
import 'package:lezgo_rider/presentation/widgets/main/merchantside/orders/merchant_order_queue_card.dart';

class _Timers extends StateNotifier<Map<int, MerchantPrepTimerEntry>>
    implements MerchantPrepTimerNotifier {
  _Timers() : super({});
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

OrderDto sample(int id, String status, String customer) => OrderDto(
  id: id,
  userId: 1,
  serviceId: 3,
  referenceNumber: 'LE-$id',
  status: status,
  pickupAddress: 'The Good Kitchen',
  dropoffAddress: '24 Mabini Street, San Fernando',
  paymentMethod: 'cash',
  paymentStatus: 'pending',
  createdAt: '2026-09-15T12:35:00',
  updatedAt: '',
  user: UserDto(id: 1, name: customer, email: 'test@example.test'),
  specialInstructions: id == 1042 ? 'Please pack the sauce separately.' : null,
  orderItems: [
    OrderItemDto(
      id: 1,
      orderId: id,
      itemName: 'Chicken teriyaki bowl',
      quantity: 2,
      unitPrice: 145,
    ),
  ],
);
final samples = [
  sample(1042, 'pending', 'Andrea Santos'),
  sample(1041, 'accepted', 'Marco Reyes'),
  sample(1040, 'ready_for_pickup', 'Mia Cruz'),
];

Future<void> mount(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool dark = false,
  Future<List<OrderDto>> Function()? load,
  bool reduced = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        merchantOrdersProvider.overrideWith(
          (ref) => load?.call() ?? Future.value(samples),
        ),
        menuItemImageLookupProvider.overrideWithValue(
          MenuItemImageLookup(byName: {}, byId: {}),
        ),
        merchantPrepTimerProvider.overrideWith((ref) => _Timers()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'TT Fors',
          brightness: dark ? Brightness.dark : Brightness.light,
          colorSchemeSeed: OrderQueuePalette.purple,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduced,
          ),
          child: child!,
        ),
        home: const Scaffold(
          body: RepaintBoundary(
            key: ValueKey('queue-preview'),
            child: MerchantOrdersView(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final font = FontLoader('TT Fors');
    font.addFont(rootBundle.load('assets/fonts/TT Fors Trial Regular.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final settings in [
    (320.0, 1.0, false),
    (320.0, 2.0, true),
    (1000.0, 1.0, false),
  ]) {
    testWidgets('queue fits width ${settings.$1}, scale ${settings.$2}', (
      tester,
    ) async {
      await mount(
        tester,
        size: Size(settings.$1, 900),
        scale: settings.$2,
        dark: settings.$3,
        reduced: settings.$3,
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -550));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(MerchantOrderQueueCard), findsWidgets);
    });
  }
  testWidgets('search narrows queue and clear restores orders', (tester) async {
    await mount(tester);
    await tester.enterText(find.byType(TextField), 'Andrea');
    await tester.pumpAndSettle();
    expect(find.text('1 order'), findsOneWidget);
    expect(find.text('Andrea Santos'), findsOneWidget);
    expect(find.text('Marco Reyes'), findsNothing);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('3 orders'), findsOneWidget);
  });
  testWidgets('accepted orders cannot be cancelled from the queue', (
    tester,
  ) async {
    await mount(
      tester,
      load: () async => [sample(1041, 'accepted', 'Marco Reyes')],
    );
    await tester.scrollUntilVisible(
      find.text('Marco Reyes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final card = find.ancestor(
      of: find.text('Marco Reyes'),
      matching: find.byType(MerchantOrderQueueCard),
    );
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('Cancel order')),
      findsNothing,
    );
    expect(
      find.descendant(of: card, matching: find.text('Mark ready for pickup')),
      findsOneWidget,
    );
  });
  testWidgets('metric filters queue and accept opens confirmation', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.text('NEW'));
    await tester.pumpAndSettle();
    expect(find.text('1 order'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Accept order'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Accept order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept order'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Accept Order?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Accept order'), findsOneWidget);
  });
  testWidgets('error retry reloads queue', (tester) async {
    var calls = 0;
    await mount(
      tester,
      load: () async {
        calls++;
        if (calls == 1) throw Exception('offline');
        return samples;
      },
    );
    await tester.scrollUntilVisible(
      find.text('Try again'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Couldn’t load your orders'), findsNothing);
  });
  testWidgets('loading and empty state render without overflow', (
    tester,
  ) async {
    final completer = Completer<List<OrderDto>>();
    await mount(tester, load: () => completer.future);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    completer.complete([]);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(find.text('Ready for your first order'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('merchant orders dark tablet visual preview', (tester) async {
    await mount(tester, size: const Size(1000, 1100), dark: true);
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('queue-preview')),
      matchesGoldenFile('goldens/merchant_orders_tablet_dark.png'),
    );
  });
  testWidgets('merchant orders visual preview', (tester) async {
    await mount(tester, size: const Size(430, 1150));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('queue-preview')),
      matchesGoldenFile('goldens/merchant_orders.png'),
    );
  });
}
