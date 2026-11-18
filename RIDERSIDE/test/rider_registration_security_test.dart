import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/data/data_source/dto/auth/register_driver_request_dto.dart';
import 'package:lezgo_rider/data/data_source/dto/auth/register_driver_response_dto.dart';
import 'package:lezgo_rider/presentation/provider/auth/rider_auth_provider.dart';
import 'package:lezgo_rider/presentation/provider/register/register_provider.dart';
import 'package:lezgo_rider/presentation/provider/register/riderside/rider_register_info_provider.dart';
import 'package:lezgo_rider/presentation/screens/register/rider/register_info_screen.dart';
import 'package:lezgo_rider/presentation/screens/register/registration_terms_screen.dart';

void main() {
  testWidgets('direct rider details route shows terms until accepted', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterInfoScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RegistrationTermsScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });
  test(
    'rider notifier cannot submit without consent or verified proof',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(registerInfoProvider.notifier);
      notifier.setPhoneProof('not-a-real-proof');
      await notifier.submitForm();
      expect(container.read(hasAcceptedTermsProvider), isFalse);
      expect(container.read(registerInfoProvider).isSubmitted, isFalse);
      expect(
        container.read(registerInfoProvider).errorMessage,
        contains('Terms & Conditions'),
      );
    },
  );
  test(
    'rider DTO defaults to no consent and retains proof only when supplied',
    () {
      final request = RegisterDriverRequestDto(
        name: 'Rider',
        email: 'rider@example.test',
        phoneNumber: '+639171234567',
        password: 'Secret123!',
        passwordConfirmation: 'Secret123!',
        licenseNumber: 'LICENSE',
      );
      expect(request.toJson()['terms_accepted'], isFalse);
      expect(request.toJson()['phone_verification_token'], isNull);
    },
  );
  test('rider response preserves fee state and missing state fails closed', () {
    for (final payment in [null, 'unpaid', 'pending', 'unknown']) {
      final dto = UserDto.fromJson({
        'id': 1,
        'name': 'Rider',
        'email': 'rider@example.test',
        'role': 'driver',
        if (payment != null)
          'registration_fee': {
            'payment_status': payment,
            'application_status': 'approved',
            'is_active': true,
          },
      });
      final user = RiderUser.fromJson(dto.toJson());
      expect(user.isRegistrationRestricted, isTrue);
      if (payment != null) expect(user.registrationFee!.paymentStatus, payment);
    }
  });
}
