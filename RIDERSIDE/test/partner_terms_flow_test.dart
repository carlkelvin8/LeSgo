import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/constants/routers/register/register_router.dart';
import 'package:lezgo_rider/core/constants/routers/register/register_routes.dart';
import 'package:lezgo_rider/core/constants/routers/main/main_routes.dart';
import 'package:lezgo_rider/presentation/provider/register/register_provider.dart';
import 'package:lezgo_rider/presentation/provider/register/riderside/rider_register_info_provider.dart';
import 'package:lezgo_rider/presentation/provider/register/merchant/merchant_register_info_provider.dart';
import 'package:lezgo_rider/presentation/screens/register/registration_terms_screen.dart';
import 'package:lezgo_rider/presentation/widgets/global/primary_button.dart';

class SuccessfulRider extends RegisterInfoNotifier {
  SuccessfulRider(super.ref);
  void succeed() => state = state.copyWith(isSubmitted: true);
}

void main() {
  for (final merchant in [false, true]) {
    testWidgets(
      'stale consent cannot unlock a new registration (merchant=$merchant)',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final subscription = container.listen(
          merchantRegisterInfoProvider,
          (_, _) {},
        );
        addTearDown(subscription.close);
        container.read(hasAcceptedTermsProvider.notifier).state = true;
        container.read(termsAcceptedProvider.notifier).state = true;
        container
            .read(merchantRegisterInfoProvider.notifier)
            .setTermsAccepted(true);
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              navigatorKey: navigator,
              onGenerateRoute: RegisterRouter.onGenerateRoute,
              home: const Scaffold(body: Text('Choose role')),
            ),
          ),
        );
        navigator.currentState!.pushNamed(
          merchant ? RegisterRoutes.merchantRegister : RegisterRoutes.riderInfo,
        );
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsNothing);
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
        expect(
          merchant
              ? container.read(merchantRegisterInfoProvider).termsAccepted
              : container.read(hasAcceptedTermsProvider),
          isFalse,
        );
        expect(
          tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
          isNull,
        );
      },
    );
  }

  for (final route in [
    RegisterRoutes.riderRegister,
    RegisterRoutes.riderInfo,
    RegisterRoutes.riderPhoneVerification,
    RegisterRoutes.merchantRegister,
  ]) {
    for (final systemBack in [false, true]) {
      testWidgets(
        '$route consent, validation, draft, cancel and re-entry (systemBack=$systemBack)',
        (tester) async {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          final navigator = GlobalKey<NavigatorState>();
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                navigatorKey: navigator,
                onGenerateRoute: RegisterRouter.onGenerateRoute,
                home: const Scaffold(body: Text('Choose role')),
              ),
            ),
          );
          navigator.currentState!.pushNamed(route);
          await tester.pumpAndSettle();
          expect(find.byType(TextFormField), findsNothing);
          expect(find.text('Continue to payment'), findsNothing);
          expect(
            tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
            isNull,
          );
          // Checking and then rejecting consent keeps the form inaccessible.
          await tester.tap(find.byType(Checkbox));
          await tester.pump();
          await tester.tap(find.byType(Checkbox));
          await tester.pump();
          expect(
            tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
            isNull,
          );
          await tester.tap(find.byType(Checkbox));
          await tester.pump();
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
          expect(find.byType(RegistrationTermsScreen), findsNothing);
          expect(find.byType(TextFormField), findsWidgets);
          await tester.enterText(
            find.byType(TextFormField).first,
            'Draft name',
          );
          final submit = tester.widget<PrimaryButton>(
            find.byType(PrimaryButton).last,
          );
          submit.onPressed!();
          await tester.pumpAndSettle();
          expect(find.byType(Form), findsOneWidget);
          expect(
            route == RegisterRoutes.merchantRegister
                ? container
                      .read(merchantRegisterInfoProvider)
                      .hasAttemptedSubmit
                : container.read(registerInfoProvider).hasAttemptedSubmit,
            isTrue,
          );
          if (systemBack) {
            await navigator.currentState!.maybePop();
          } else {
            await tester.tap(find.byIcon(Icons.chevron_left_rounded));
          }
          await tester.pumpAndSettle();
          expect(find.byType(RegistrationTermsScreen), findsOneWidget);
          expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
          expect(
            route == RegisterRoutes.merchantRegister
                ? container.read(merchantRegisterInfoProvider).termsAccepted
                : container.read(hasAcceptedTermsProvider),
            isFalse,
          );
          // Reaccepting retains the in-progress form.
          await tester.tap(find.byType(Checkbox));
          await tester.pump();
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<TextFormField>(find.byType(TextFormField).first)
                .controller!
                .text,
            'Draft name',
          );
          await navigator.currentState!.maybePop();
          await tester.pumpAndSettle();
          // Cancel from terms (including with the checkbox checked).
          await tester.tap(find.byType(Checkbox));
          await tester.pump();
          if (systemBack) {
            await navigator.currentState!.maybePop();
          } else {
            await tester.tap(find.byIcon(Icons.chevron_left_rounded));
          }
          await tester.pumpAndSettle();
          expect(find.text('Choose role'), findsOneWidget);
          navigator.currentState!.pushNamed(route);
          await tester.pumpAndSettle();
          expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
          expect(find.byType(TextFormField), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'rider success opens payment only after consent and form, clearing history',
    (tester) async {
      late SuccessfulRider registration;
      RouteSettings? destination;
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registerInfoProvider.overrideWith(
              (ref) => registration = SuccessfulRider(ref),
            ),
          ],
          child: MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(body: Text('Choose role')),
            onGenerateRoute: (settings) {
              final registrationRoute = RegisterRouter.onGenerateRoute(
                settings,
              );
              if (registrationRoute != null) return registrationRoute;
              destination = settings;
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Payment')),
              );
            },
          ),
        ),
      );
      navigator.currentState!.pushNamed(RegisterRoutes.riderRegister);
      await tester.pumpAndSettle();
      expect(destination, isNull);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(destination, isNull);
      registration.succeed();
      await tester.pumpAndSettle();
      expect(destination!.name, MainRoutes.registrationFeeStatus);
      expect(destination!.arguments, {'target': MainRoutes.riderMain});
      expect(navigator.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
