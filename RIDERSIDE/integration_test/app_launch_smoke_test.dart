import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lezgo_rider/main.dart' as app;
import 'package:lezgo_rider/presentation/screens/auth/auth_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_main_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_main_screen.dart';
import 'package:lezgo_rider/presentation/screens/registration_fee_screen.dart';
import 'package:lezgo_rider/presentation/widgets/auth/welcome_content.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rider app reaches a launch destination on Android', (
    tester,
  ) async {
    await app.main();

    bool reachedDestination() =>
        find.byType(AuthScreen).evaluate().isNotEmpty ||
        find.byType(RiderMainScreen).evaluate().isNotEmpty ||
        find.byType(MerchantMainScreen).evaluate().isNotEmpty ||
        find.byType(RegistrationFeeScreen).evaluate().isNotEmpty;

    for (var i = 0; i < 240 && !reachedDestination(); i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(reachedDestination(), isTrue);
    if (find.byType(AuthScreen).evaluate().isNotEmpty) {
      expect(find.byType(WelcomeContent), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
