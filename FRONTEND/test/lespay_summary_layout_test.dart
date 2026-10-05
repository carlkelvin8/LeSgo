import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/presentation/provider/main/lespay/lespay_provider.dart';
import 'package:lesgo/presentation/screens/main/lespay_screen.dart';

class _Wallet extends LespayNotifier {
  _Wallet() {
    state = const LespayState(balance: 5, walletLoaded: true);
  }

  @override
  Future<void> refreshBalance() async {}
  @override
  Future<void> loadTransactions() async {}
}

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('wallet omits summary cards at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [lespayProvider.overrideWith((ref) => _Wallet())],
        child: const MaterialApp(home: LespayScreen()),
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('This Month'), findsNothing);
      expect(find.text('Spent'), findsNothing);
      expect(find.text('Saved'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
