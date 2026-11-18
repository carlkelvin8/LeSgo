import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_payout_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_payout_screen.dart';

class _Payout extends RiderPayoutNotifier {
  _Payout() : super() {
    state = const RiderPayoutState(availableBalance: 10000);
  }

  @override
  Future<void> loadPayoutData() async {}
}

void main() {
  testWidgets('payout summary fits a standard 360 px emulator width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'app_language': 'en'});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          riderPayoutProvider.overrideWith((ref) => _Payout()),
          riderPayoutHistoryProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: RiderPayoutScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('PHP 10000.00'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
