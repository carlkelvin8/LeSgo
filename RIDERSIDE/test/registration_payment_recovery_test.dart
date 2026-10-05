import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/services/registration_fee_api.dart';
import 'package:lezgo_rider/domain/entities/auth/registration_fee_status.dart';
import 'package:lezgo_rider/presentation/provider/auth/registration_fee_provider.dart';
import 'package:lezgo_rider/presentation/screens/registration_fee_screen.dart';

RegistrationFeeStatus status(String payment) => RegistrationFeeStatus.fromJson({
  'payment_status': payment, 'application_status': 'pending', 'is_active': false,
  'checkout_url': 'https://checkout.example.test/saved', 'paymongo_checkout_id': 'cs_saved',
})!;

void main() {
  for (final throws in [false, true]) {
    testWidgets('restart resumes saved checkout and recovers launch failure ($throws)', (tester) async {
      var creates = 0;
      var loads = 0;
      String? verifiedId;
      final notifier = RegistrationFeeNotifier(
        fetchStatus: () async { loads++; return status('pending'); },
        createCheckout: () async { creates++; return const RegistrationFeeCheckout(); },
        verify: ({checkoutId}) async { verifiedId = checkoutId; return status('paid'); },
      );
      final urls = <Uri>[];
      await tester.pumpWidget(ProviderScope(overrides: [
        registrationFeeProvider.overrideWith((_) => notifier),
        registrationPaymentLauncherProvider.overrideWithValue((uri) async {
          urls.add(uri);
          if (throws) throw Exception('No browser');
          return false;
        }),
      ], child: const MaterialApp(home: RegistrationFeeScreen())));
      await tester.pumpAndSettle();
      expect(find.text('Resume Payment'), findsOneWidget);
      expect(find.text('Verify Payment'), findsOneWidget);
      await tester.tap(find.text('Resume Payment'));
      await tester.pumpAndSettle();
      expect(urls.single.toString(), 'https://checkout.example.test/saved');
      expect(creates, 0);
      expect(find.textContaining('Could not open payment'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(loads, 2);
      await tester.tap(find.text('Verify Payment'));
      await tester.pumpAndSettle();
      expect(verifiedId, 'cs_saved');
      expect(find.text('Continue to App'), findsNothing);
      expect(notifier.state.status!.awaitingApprovalAfterPayment, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
  test('verification network failure keeps saved checkout for retry', () async {
    final notifier = RegistrationFeeNotifier(fetchStatus: () async => status('pending'),
      verify: ({checkoutId}) async => throw Exception('offline'));
    addTearDown(notifier.dispose);
    await notifier.loadStatus();
    expect(await notifier.verifyPayment(), isFalse);
    expect(notifier.state.status!.paymongoCheckoutId, 'cs_saved');
    expect(notifier.state.isProcessing, isFalse);
    expect(notifier.state.error, isNotNull);
  });
}
