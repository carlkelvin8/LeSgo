import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/presentation/widgets/main/merchantside/menu/merchant_menu_setup_card.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('Menu setup fits narrow screen and large text, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: MerchantMenuSetupCard(
                  isDark: dark,
                  actionLabel: 'Add category',
                  onAction: () => tapped = true,
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Add category'));
      await tester.tap(find.text('Add category'));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
