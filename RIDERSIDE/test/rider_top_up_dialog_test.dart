import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_wallet_provider.dart';
import 'package:lezgo_rider/presentation/widgets/main/riderside/wallet/rider_top_up_dialog.dart';

class _Wallet extends RiderWalletNotifier {
  @override
  Future<void> loadWallet({bool silent = false}) async {}
}

class _PaidWallet extends _Wallet {
  int polls = 0;

  @override
  Future<RiderTopUpCheckout?> startTopUp(double walletAmount) async =>
      RiderTopUpCheckout(
        invoiceId: 'rider-checkout',
        invoiceUrl: 'https://checkout.example/pay',
        walletAmount: walletAmount,
        feeAmount: 7.5,
        totalCharge: 507.5,
      );

  @override
  Future<bool> pollInvoicePaid(String invoiceId) async => ++polls >= 2;

  @override
  Future<bool> completeTopUp(RiderTopUpCheckout checkout) async {
    state = state.copyWith(balance: 500);
    return true;
  }
}

void main() {
  testWidgets(
    'delayed payment refreshes wallet and safely returns from closed dialog',
    (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (_) async => true,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        ),
      );
      final wallet = _PaidWallet();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [riderWalletProvider.overrideWith((ref) => wallet)],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => RiderTopUpDialog(parentContext: context),
                  ),
                  child: const Text('Add funds'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Add funds'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('₱500'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(wallet.polls, greaterThanOrEqualTo(2));
      expect(wallet.state.balance, 500);
      expect(find.text('Add funds'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('Top up fits narrow screen and keyboard at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [riderWalletProvider.overrideWith((ref) => _Wallet())],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                viewInsets: const EdgeInsets.only(bottom: 280),
              ),
              child: child!,
            ),
            home: Builder(
              builder: (context) =>
                  Scaffold(body: RiderTopUpDialog(parentContext: context)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('₱500'));
      await tester.tap(find.text('₱500'));
      await tester.pumpAndSettle();
      expect(find.text('₱7.50'), findsOneWidget);
      expect(find.text('₱507.50'), findsOneWidget);
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
