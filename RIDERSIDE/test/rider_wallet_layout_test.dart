import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_wallet_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_wallet_view.dart';

class _Wallet extends RiderWalletNotifier {
  _Wallet(RiderWalletState initial) {
    state = initial;
  }
  int refreshes = 0;
  @override
  Future<void> loadWallet({bool silent = false}) async {
    refreshes++;
  }

  void update(RiderWalletState value) {
    state = value;
  }
}

Future<void> _mountWallet(
  WidgetTester tester,
  _Wallet wallet, {
  double width = 390,
  double scale = 1,
  bool dark = false,
  bool filipino = false,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    'app_language': filipino ? 'tl' : 'en',
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [riderWalletProvider.overrideWith((ref) => wallet)],
      child: MaterialApp(
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const RiderWalletScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('Wallet fits $width px with large Filipino text', (
      tester,
    ) async {
      await _mountWallet(
        tester,
        _Wallet(const RiderWalletState(balance: 123456789.12)),
        width: width,
        scale: 2,
        filipino: true,
        dark: true,
      );
      expect(find.text('₱ 123,456,789.12'), findsOneWidget);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1400),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Hidden balance stays private through refresh and error states', (
    tester,
  ) async {
    final wallet = _Wallet(const RiderWalletState(balance: 1234.56));
    await _mountWallet(tester, wallet);
    await tester.tap(find.byTooltip('Hide balance'));
    await tester.pump();
    expect(find.text('₱ 1,234.56'), findsNothing);
    expect(find.text('••••••'), findsOneWidget);
    wallet.update(const RiderWalletState(balance: 9876.54, isLoading: true));
    await tester.pump();
    expect(find.textContaining('9,876.54'), findsNothing);
    wallet.update(
      const RiderWalletState(balance: 9876.54, error: 'Balance 9876.54 stale'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('9876.54'), findsNothing);
    await tester.tap(find.byTooltip('Show balance'));
    await tester.pumpAndSettle();
    expect(find.text('₱ 9,876.54'), findsOneWidget);
  });

  testWidgets(
    'Booking threshold, refresh and error recovery remain available',
    (tester) async {
      final wallet = _Wallet(const RiderWalletState(balance: 10));
      await _mountWallet(tester, wallet);
      expect(find.textContaining('Keep at least PHP 11'), findsOneWidget);
      await tester.tap(find.byTooltip('Refresh balance'));
      expect(wallet.refreshes, greaterThan(1));
      wallet.update(const RiderWalletState(balance: 11));
      await tester.pumpAndSettle();
      expect(find.text('Top up to keep taking bookings'), findsNothing);
      wallet.update(const RiderWalletState(balance: 11, error: 'offline'));
      await tester.pumpAndSettle();
      expect(find.text('Could not refresh your wallet'), findsOneWidget);
      final beforeRetry = wallet.refreshes;
      await tester.ensureVisible(find.text('Try Again'));
      await tester.tap(find.text('Try Again'));
      expect(wallet.refreshes, beforeRetry + 1);
      expect(tester.takeException(), isNull);
    },
  );
}
