import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/domain/entities/auth/registration_fee_status.dart';
import 'package:lezgo_rider/presentation/provider/auth/registration_fee_provider.dart';
import 'package:lezgo_rider/presentation/widgets/main/merchantside/merchant_renewal_banner.dart';

RegistrationFeeStatus _status({
  required String? expiresAt,
  String billing = 'annual',
  String payment = 'paid',
  bool grandfathered = false,
}) => RegistrationFeeStatus.fromJson({
  'requires_fee': true,
  'payment_status': payment,
  'application_status': 'approved',
  'billing_period': billing,
  'amount': 1000,
  'currency': 'PHP',
  'registration_expires_at': expiresAt,
  'is_grandfathered': grandfathered,
})!;

String _in(int days, DateTime now) =>
    DateTime(now.year, now.month, now.day, 12).add(Duration(days: days)).toIso8601String();

void main() {
  final now = DateTime(2026, 11, 18, 9);

  group('RegistrationFeeStatus renewal window', () {
    test('due soon inside 30 days, including today and day 30', () {
      expect(_status(expiresAt: _in(0, now)).renewalDueSoon(now: now), isTrue);
      expect(_status(expiresAt: _in(20, now)).renewalDueSoon(now: now), isTrue);
      expect(_status(expiresAt: _in(30, now)).renewalDueSoon(now: now), isTrue);
    });

    test('not due soon beyond 30 days or once already expired', () {
      expect(_status(expiresAt: _in(31, now)).renewalDueSoon(now: now), isFalse);
      expect(_status(expiresAt: _in(-1, now)).renewalDueSoon(now: now), isFalse);
    });

    test('never for exempt partners, riders, unpaid fees or no date', () {
      expect(_status(expiresAt: _in(5, now), grandfathered: true).renewalDueSoon(now: now), isFalse);
      expect(_status(expiresAt: _in(5, now), billing: 'one_time').renewalDueSoon(now: now), isFalse);
      expect(_status(expiresAt: _in(5, now), payment: 'unpaid').renewalDueSoon(now: now), isFalse);
      expect(_status(expiresAt: null).renewalDueSoon(now: now), isFalse);
    });

    test('a waived annual partner is reminded too', () {
      expect(_status(expiresAt: _in(10, now), payment: 'waived').renewalDueSoon(now: now), isTrue);
    });

    test('counts whole calendar days', () {
      expect(_status(expiresAt: _in(20, now)).daysUntilRenewal(now: now), 20);
    });
  });

  group('MerchantRenewalBanner', () {
    Future<void> pump(WidgetTester tester, RegistrationFeeStatus status) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registrationFeeProvider.overrideWith(
              (ref) => RegistrationFeeNotifier(fetchStatus: () async => status),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: MerchantRenewalBanner())),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('shows the date and amount when due soon', (tester) async {
      final real = DateTime.now();
      await pump(tester, _status(expiresAt: _in(12, real)));

      expect(find.byKey(const ValueKey('merchant-renewal-banner')), findsOneWidget);
      expect(find.textContaining('in 12 days'), findsOneWidget);
      expect(find.textContaining('PHP 1000.00'), findsOneWidget);
    });

    testWidgets('renders nothing for an exempt partner', (tester) async {
      final real = DateTime.now();
      await pump(tester, _status(expiresAt: _in(12, real), grandfathered: true));

      expect(find.byKey(const ValueKey('merchant-renewal-banner')), findsNothing);
    });

    testWidgets('renders nothing when the renewal is far away', (tester) async {
      final real = DateTime.now();
      await pump(tester, _status(expiresAt: _in(200, real)));

      expect(find.byKey(const ValueKey('merchant-renewal-banner')), findsNothing);
    });
  });
}
