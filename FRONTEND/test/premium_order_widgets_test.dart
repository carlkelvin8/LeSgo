import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/presentation/widgets/orders/premium_order_widgets.dart';

void main() {
  test('tidy removes repeated address pieces', () {
    expect(
      OrderAddress.tidy('Claveria, Cagayan, Claveria, Cagayan Valley'),
      'Claveria, Cagayan Valley',
    );
    expect(OrderAddress.tidy('Centro I, Claveria, Cagayan Valley'),
        'Centro I, Claveria, Cagayan Valley');
    expect(OrderAddress.split('Sunset Cafe, Claveria').$1, 'Sunset Cafe');
    expect(OrderAddress.tidy(''), '');
  });

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('cards fit at ${width}px / ${scale}x text', (tester) async {
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const OrderHero(
                        service: 'LesEat',
                        headline: 'Scheduled for later',
                        statusLabel: 'Scheduled',
                        statusIcon: Icons.schedule_rounded,
                        date: 'Nov 19, 2026 • 12:04 AM',
                        stepLabels: ['Placed', 'Preparing', 'On the way', 'Done'],
                        stepIndex: 1,
                      ),
                      const RouteCard(
                        pickup: 'Claveria, Cagayan, Claveria, Cagayan Valley',
                        dropoff: 'Centro I, Claveria, Cagayan Valley',
                      ),
                      ReceiptCard(
                        items: const [
                          ReceiptItem(qty: 2, name: '1-pc Chickenjoy', price: '₱178.00'),
                        ],
                        rows: const [ReceiptRow('Subtotal', '₱178.00')],
                        total: '₱233.00',
                        footer: const PaymentStrip(
                          method: 'Cash',
                          status: 'Not charged',
                          statusColor: Colors.grey,
                        ),
                      ),
                      PremiumButton(label: 'Reorder', onPressed: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Claveria, Cagayan Valley'), findsWidgets);
      });
    }
  }
}
