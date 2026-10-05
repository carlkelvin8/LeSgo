import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_duty_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_orders_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_location_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_wallet_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_bookings_view.dart';

class _Duty extends StateNotifier<bool> implements RiderDutyNotifier {
  _Duty() : super(true);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Orders extends StateNotifier<RiderOrdersState>
    implements RiderOrdersNotifier {
  _Orders() : super(RiderOrdersState());
  int refreshes = 0;
  @override
  Future<void> loadOrders({bool silent = false}) async {
    refreshes++;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Location extends StateNotifier<RiderLocationState>
    implements RiderLocationNotifier {
  _Location() : super(const RiderLocationState());
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Wallet extends StateNotifier<RiderWalletState>
    implements RiderWalletNotifier {
  _Wallet() : super(const RiderWalletState(balance: 500));
  @override
  Future<void> loadWallet({bool silent = false}) async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  for (final large in [false, true]) {
    testWidgets('Booking screen fits and refresh works, large: $large', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'app_language': large ? 'tl' : 'en',
      });
      final orders = _Orders();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            riderDutyProvider.overrideWith((ref) => _Duty()),
            riderOrdersProvider.overrideWith((ref) => orders),
            riderLocationProvider.overrideWith((ref) => _Location()),
            riderWalletProvider.overrideWith((ref) => _Wallet()),
          ],
          child: MaterialApp(
            theme: ThemeData(
              brightness: large ? Brightness.dark : Brightness.light,
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(large ? 2 : 1),
                disableAnimations: large,
              ),
              child: child!,
            ),
            home: const Scaffold(body: RiderBookingsView()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byWidgetPredicate((widget) => widget is FilledButton),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(
        find.byWidgetPredicate((widget) => widget is FilledButton),
      );
      await tester.pumpAndSettle();
      expect(orders.refreshes, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
