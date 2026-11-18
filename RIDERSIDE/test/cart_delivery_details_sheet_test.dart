import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/presentation/provider/cart/cart_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_profile_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/cart_screen.dart';

class _TestCartNotifier extends CartNotifier {
  _TestCartNotifier() {
    addItem(name: 'QA Pancake', size: 'Regular', unitPrice: 49, menuItemId: 99);
  }
}

void main() {
  testWidgets('invalid delivery details stay in the sheet without crashing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cartProvider.overrideWith((ref) => _TestCartNotifier()),
          merchantProfileProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: CartScreen()),
      ),
    );
    await tester.pump();
    expect(
      tester.takeException(),
      isNull,
      reason: 'cart screen initial layout',
    );

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    expect(find.text('Delivery Details'), findsOneWidget);
    await tester.tap(find.text('Place Order'));
    await tester.pump();
    expect(find.text('Please enter a delivery address.'), findsOneWidget);
    expect(find.text('Delivery Details'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final address = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Delivery address',
    );
    await tester.enterText(address, 'QA test address');
    await tester.tap(find.text('Place Order'));
    await tester.pump();

    expect(
      find.text(
        'Pin the delivery location so the delivery fee can be calculated.',
      ),
      findsOneWidget,
    );
    expect(find.text('Delivery Details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
