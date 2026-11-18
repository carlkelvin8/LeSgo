import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/data/data_source/dto/order/order_dto.dart';
import 'package:lesgo/presentation/widgets/orders/order_card.dart';

/// A real LesEat order from the sandbox API: 2 x P89 items + P55 delivery.
Map<String, dynamic> _foodOrderJson() =>
    jsonDecode(File('test/fixtures/leseat_order.json').readAsStringSync())
        as Map<String, dynamic>;

Future<void> _pumpCard(WidgetTester tester, OrderDto order) async {
  // The test font is much wider than the app font; give the card room so a
  // font-metrics overflow does not mask what these tests check.
  tester.view.physicalSize = const Size(1100, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: OrderCard(order: order, onTap: () {})),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test('a food order\'s estimated fare is only the delivery fee', () {
    final order = OrderDto.fromJson(_foodOrderJson());

    expect(order.estimatedFare, 55);
    expect(order.effectiveTotalAmount, 233, reason: 'items 178 + delivery 55');
  });

  testWidgets('history card shows what the customer pays for a food order',
      (tester) async {
    await _pumpCard(tester, OrderDto.fromJson(_foodOrderJson()));

    expect(find.text('₱233.00'), findsOneWidget);
    expect(find.text('₱55.00'), findsNothing);
  });

  testWidgets('a ride still shows its fare', (tester) async {
    final json = _foodOrderJson()
      ..['estimated_fare'] = '60.00'
      ..['lesbuy_items'] = <dynamic>[]
      ..['meta'] = {'order_type': 'lesride', 'subtotal': 0, 'delivery_fee': 60, 'grand_total': 60, 'total': 60};
    await _pumpCard(tester, OrderDto.fromJson(json));

    expect(find.text('₱60.00'), findsOneWidget);
  });

  testWidgets('an order without a recorded total falls back to its fare',
      (tester) async {
    final json = _foodOrderJson()
      ..['estimated_fare'] = '75.00'
      ..['lesbuy_items'] = <dynamic>[]
      ..['meta'] = {'order_type': 'lesgo'};
    await _pumpCard(tester, OrderDto.fromJson(json));

    expect(find.text('₱75.00'), findsOneWidget);
  });
}
