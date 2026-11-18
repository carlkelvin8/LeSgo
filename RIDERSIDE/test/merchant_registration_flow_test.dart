import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/constants/merchant_terms.dart';
import 'package:lezgo_rider/core/constants/routers/main/main_routes.dart';
import 'package:lezgo_rider/data/data_source/dto/auth/register_merchant_request_dto.dart';
import 'package:lezgo_rider/data/data_source/dto/auth/register_merchant_response_dto.dart';
import 'package:lezgo_rider/domain/entities/auth/registration_fee_status.dart';
import 'package:lezgo_rider/presentation/provider/auth/registration_fee_provider.dart';
import 'package:lezgo_rider/presentation/provider/auth/rider_auth_provider.dart';
import 'package:lezgo_rider/presentation/provider/register/merchant/merchant_register_info_provider.dart';
import 'package:lezgo_rider/presentation/screens/register/merchant/merchant_register_screen.dart';
import 'package:lezgo_rider/presentation/screens/register/merchant/merchant_terms_screen.dart';
import 'package:lezgo_rider/presentation/screens/registration_fee_screen.dart';
import 'package:lezgo_rider/presentation/widgets/global/primary_button.dart';

RegistrationFeeStatus fee(String payment, String application, {bool? active}) =>
    RegistrationFeeStatus.fromJson({
      'payment_status': payment,
      'application_status': application,
      'is_active':
          active ??
          (['paid', 'waived'].contains(payment) && application == 'approved'),
      'amount': 1000,
      'billing_period': 'annual',
    })!;

class TestFeeNotifier extends RegistrationFeeNotifier {
  TestFeeNotifier(RegistrationFeeStatus status) {
    state = RegistrationFeeState(status: status);
  }
  @override
  Future<void> loadStatus({bool silent = false}) async {}
}

class TestAuthNotifier extends RiderAuthNotifier {
  TestAuthNotifier() {
    state = RiderAuthState(
      isLoggedIn: true,
      user: RiderUser(
        id: 1,
        name: 'Merchant',
        email: 'merchant@example.test',
        role: 'partner_admin',
        partnerId: 2,
        registrationFee: fee('unpaid', 'pending'),
      ),
    );
  }
}

class TestMerchantRegistration extends MerchantRegisterInfoNotifier {
  TestMerchantRegistration(super.ref);

  void registrationSucceeded() {
    state = state.copyWith(isSubmitted: true);
  }
}

void main() {
  testWidgets('merchant registration starts with unchecked MOU acceptance', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MerchantRegisterScreen()),
      ),
    );
    expect(find.byType(MerchantTermsScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).data,
      MerchantTerms.content,
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(container.read(merchantRegisterInfoProvider).termsAccepted, isFalse);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(container.read(merchantRegisterInfoProvider).termsAccepted, isTrue);
    expect(find.byType(MerchantTermsScreen), findsNothing);
    expect(find.text('Continue to payment'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Review Merchant Terms & Conditions'));
    await tester.pumpAndSettle();
    expect(find.byType(MerchantTermsScreen), findsOneWidget);
    expect(container.read(merchantRegisterInfoProvider).termsAccepted, isFalse);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });

  testWidgets(
    'successful registration goes straight to merchant payment and clears registration history',
    (tester) async {
      late TestMerchantRegistration registration;
      RouteSettings? destination;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            merchantRegisterInfoProvider.overrideWith((ref) {
              registration = TestMerchantRegistration(ref);
              return registration;
            }),
          ],
          child: MaterialApp(
            home: const MerchantRegisterScreen(),
            onGenerateRoute: (settings) {
              destination = settings;
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) =>
                    const Scaffold(body: Text('Registration payment')),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      registration.registrationSucceeded();
      await tester.pumpAndSettle();
      expect(destination!.name, MainRoutes.registrationFeeStatus);
      expect(destination!.arguments, {'target': MainRoutes.merchantMain});
      expect(find.text('Registration payment'), findsOneWidget);
      expect(
        Navigator.of(
          tester.element(find.text('Registration payment')),
        ).canPop(),
        isFalse,
      );
    },
  );

  test('submission cannot bypass terms even through the notifier', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final keepAlive = container.listen(merchantRegisterInfoProvider, (_, _) {});
    addTearDown(keepAlive.close);
    await container.read(merchantRegisterInfoProvider.notifier).attemptSubmit();
    final state = container.read(merchantRegisterInfoProvider);
    expect(state.termsAccepted, isFalse);
    expect(state.isSubmitted, isFalse);
    expect(state.isSubmitting, isFalse);
    expect(state.errorMessage, contains('Terms & Conditions'));
  });

  test('merchant request does not invent consent when omitted', () {
    final request = RegisterMerchantRequestDto(
      name: 'Merchant',
      email: 'merchant@example.test',
      password: 'Secret123!',
      passwordConfirmation: 'Secret123!',
      restaurantName: 'Store',
    );
    expect(request.toJson()['terms_accepted'], isFalse);
    final json = request.toJson()..remove('terms_accepted');
    expect(RegisterMerchantRequestDto.fromJson(json).termsAccepted, isFalse);
  });

  test(
    'merchant response retains fee status when establishing the session',
    () {
      final dto = MerchantUserDto.fromJson({
        'id': 1,
        'name': 'Merchant',
        'email': 'merchant@example.test',
        'role': 'partner_admin',
        'partner_id': 2,
        'registration_fee': {
          'is_active': false,
          'payment_status': 'unpaid',
          'application_status': 'pending',
        },
      });
      final user = RiderUser.fromJson(dto.toJson());
      expect(user.registrationFee, isNotNull);
      expect(user.registrationFee!.paymentStatus, 'unpaid');
      expect(user.isRegistrationRestricted, isTrue);
    },
  );

  test('missing merchant payment status denies account access', () {
    final user = RiderUser(
      id: 1,
      name: 'Merchant',
      email: 'merchant@example.test',
      role: 'partner_admin',
    );
    expect(user.isRegistrationRestricted, isTrue);
  });

  for (final pair in [
    ['unpaid', 'pending'],
    ['paid', 'pending'],
    ['unpaid', 'approved'],
    ['pending', 'approved'],
    ['failed', 'approved'],
    ['paid', 'rejected'],
  ]) {
    testWidgets('${pair.join('/')} does not expose account access', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registrationFeeProvider.overrideWith(
              (ref) => TestFeeNotifier(fee(pair[0], pair[1])),
            ),
          ],
          child: const MaterialApp(
            home: RegistrationFeeScreen(
              targetMainRoute: MainRoutes.merchantMain,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue to App'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'unpaid status stays blocked even with an inconsistent active flag',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registrationFeeProvider.overrideWith(
              (ref) => TestFeeNotifier(fee('unpaid', 'approved', active: true)),
            ),
          ],
          child: const MaterialApp(
            home: RegistrationFeeScreen(
              targetMainRoute: MainRoutes.merchantMain,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue to App'), findsNothing);
    },
  );

  for (final payment in ['paid', 'waived']) {
    testWidgets(
      '$payment and approved updates the session before opening merchant account',
      (tester) async {
        final auth = TestAuthNotifier();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              registrationFeeProvider.overrideWith(
                (ref) => TestFeeNotifier(fee(payment, 'approved')),
              ),
              riderAuthProvider.overrideWith((ref) => auth),
            ],
            child: MaterialApp(
              home: const RegistrationFeeScreen(
                targetMainRoute: MainRoutes.merchantMain,
              ),
              routes: {
                MainRoutes.merchantMain: (_) =>
                    const Scaffold(body: Text('Merchant account')),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(auth.state.user!.isRegistrationRestricted, isTrue);
        await tester.tap(find.text('Continue to App'));
        await tester.pumpAndSettle();
        expect(find.text('Merchant account'), findsOneWidget);
        expect(auth.state.user!.isRegistrationRestricted, isFalse);
        expect(auth.state.user!.registrationFee!.paymentStatus, payment);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
