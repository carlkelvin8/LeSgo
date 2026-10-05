import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/presentation/widgets/lespay/wallet_card.dart';
import 'package:lesgo/presentation/widgets/lespay/lespay_actions_section.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('wallet and actions fit width $width with large text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var visibilityChanges = 0;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: const TextScaler.linear(1.6),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      WalletCard(
                        balance: 123456789.12,
                        onToggleVisibility: () => visibilityChanges++,
                      ),
                      const SizedBox(height: 24),
                      const LespayActionsSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat indefinitely.
      expect(tester.takeException(), isNull);
      final title = find.text('My LesPay Wallet');
      if (title.evaluate().isNotEmpty) {
        expect(
          tester
              .getRect(title)
              .overlaps(
                tester.getRect(
                  find.byIcon(Icons.account_balance_wallet_outlined),
                ),
              ),
          isFalse,
        );
      }
      await tester.tap(find.byTooltip('Hide balance'));
      expect(visibilityChanges, 1);
      expect(find.text('Payment Methods'), findsOneWidget);
    });
  }
}
