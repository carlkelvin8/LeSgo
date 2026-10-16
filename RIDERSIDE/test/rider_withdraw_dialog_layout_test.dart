import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_wallet_provider.dart';
import 'package:lezgo_rider/presentation/widgets/main/riderside/wallet/rider_wallet_withdraw_dialog.dart';

class _Wallet extends RiderWalletNotifier {
  _Wallet() {
    state = const RiderWalletState(balance: 0);
  }

  @override
  Future<void> loadWallet({bool silent = false}) async {}
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('Withdraw dialog fits narrow screen at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [riderWalletProvider.overrideWith((ref) => _Wallet())],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => RiderWalletWithdrawDialog(
                      parentContext: context,
                      availableBalance: 0,
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Available to withdraw'), findsOneWidget);
      expect(find.byType(SegmentedButton<String>), findsNothing);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
