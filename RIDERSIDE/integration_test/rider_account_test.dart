// Rider session / account lifecycle, driven through the real UI, with every
// outcome asserted against the LOCAL backend. Destructive steps (change
// password, deactivate, delete) only ever run on THROWAWAY drivers that the
// test registers itself through the public API; the seeded rider is untouched.
//
// Run (local API on :8012):
//   flutter test integration_test/rider_account_test.dart \
//     -d A25FDC04-97C0-488D-84E0-1542AA1EFA59 \
//     --dart-define=API_BASE_URL=http://127.0.0.1:8012/api \
//     --dart-define=LES_GO_TEST_RIDER_EMAIL=testrider@lesgo.com \
//     --dart-define=LES_GO_TEST_RIDER_PASSWORD='TestRider123!'
// The forgot-password step reads the OTP from the local backend's mail log
// (override with --dart-define=LES_GO_BACKEND_LOG=/path/to/laravel.log).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lezgo_rider/core/constants/routers/main/main_routes.dart';
import 'package:lezgo_rider/core/services/notification_navigation_service.dart';
import 'package:lezgo_rider/core/constants/routers/register/register_routes.dart';
import 'package:lezgo_rider/core/services/remember_me_service.dart';
import 'package:lezgo_rider/core/services/secure_storage_service.dart';
import 'package:lezgo_rider/main.dart' as app;
import 'package:lezgo_rider/presentation/screens/register/rider/register_info_screen.dart';
import 'package:lezgo_rider/presentation/widgets/widgets.dart' show PrimaryButton;
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_change_password_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_deactivate_account_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_delete_account_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_main_screen.dart';

import 'support/rider_e2e_support.dart';

const _logPath = String.fromEnvironment(
  'LES_GO_BACKEND_LOG',
  defaultValue:
      '/Users/carlkelvinmanahan/Documents/LeSgo/BACKEND/lesgo-api/storage/logs/laravel.log',
);

final api = E2eApi();
final failures = <String>[];
WidgetTester? _tester;

Future<void> step(String name, Future<void> Function() body) async {
  // ignore: avoid_print
  print('=== STEP: $name');
  try {
    await body();
    // ignore: avoid_print
    print('=== PASS: $name');
  } catch (e, st) {
    // ignore: avoid_print
    print('=== FAIL: $name -> $e\n$st');
    failures.add(name);
    if (_tester != null) dumpScreen(_tester!, name);
  }
}

NavigatorState get _nav =>
    NotificationNavigationService.navigatorKey.currentState!;

Finder get _loginButton => find.text('Login');

/// Dismisses any floating snackbar (they cover the bottom buttons for ~4s),
/// then presses the button: PrimaryButtons by invoking their onPressed (the
/// same handler a tap runs), anything else with a normal tap.
Future<void> _tapClear(WidgetTester t, Finder f) async {
  final ctx = t.element(find.byType(Scaffold).last);
  ScaffoldMessenger.of(ctx).clearSnackBars();
  await t.pump(const Duration(milliseconds: 1000));
  final label = f.evaluate().isEmpty ? null : (f.evaluate().first.widget as Text).data;
  final primary = label == null
      ? find.byType(PrimaryButton)
      : find.widgetWithText(PrimaryButton, label);
  if (primary.evaluate().isNotEmpty) {
    final cb = t.widget<PrimaryButton>(primary.last).onPressed;
    if (cb != null) {
      cb();
      await t.pump(const Duration(milliseconds: 300));
      return;
    }
  }
  await t.ensureVisible(f);
  await t.tap(f, warnIfMissed: false);
}

Finder get _riderLoginForm => find.byKey(const ValueKey('rider_login_form'));

/// After a logout the app lands directly on the Rider login form; from a cold
/// start it shows the Login / Rider chooser first. Handles both.
Future<void> _openRiderLoginForm(WidgetTester t) async {
  await pumpUntilAny(t, [_riderLoginForm, _loginButton],
      what: 'login form or Login button');
  if (_riderLoginForm.evaluate().isNotEmpty) return;
  await t.tap(_loginButton.first);
  await t.pumpAndSettle();
  final btn = find.text('Rider');
  if (btn.evaluate().isNotEmpty) {
    await t.tap(btn.first);
    await t.pumpAndSettle();
  }
  await pumpUntil(t, _riderLoginForm, what: 'rider login form');
}

/// Logs in on the Rider form.
Future<void> _loginFromStartScreen(WidgetTester t, String email, String pw) async {
  await _openRiderLoginForm(t);
  final fields =
      find.descendant(of: _riderLoginForm, matching: find.byType(TextFormField));
  await t.enterText(fields.at(0), email);
  await t.enterText(fields.at(1), pw);
  FocusManager.instance.primaryFocus?.unfocus();
  await t.pumpAndSettle();
  await _tapClear(t, find.text('Log In'));
}

Future<void> _openProfile(WidgetTester t) async {
  await tapRiderTab(t, 'Profile');
  await settle(t, 800);
}

Future<void> _logoutViaUi(WidgetTester t) async {
  await _openProfile(t);
  final icon = find.byIcon(Icons.exit_to_app_rounded);
  await pumpUntil(t, icon, what: 'logout icon');
  await t.tap(icon.first);
  await pumpUntil(t, find.text('Are you sure you want to logout?'),
      what: 'logout dialog');
  await t.tap(find.widgetWithText(ElevatedButton, 'Logout').evaluate().isNotEmpty
      ? find.widgetWithText(ElevatedButton, 'Logout')
      : find.text('Logout').last);
}

Future<String?> _latestResetOtp() async {
  final f = File(_logPath);
  if (!f.existsSync()) return null;
  final len = f.lengthSync();
  final raf = f.openSync();
  try {
    final start = len > 200000 ? len - 200000 : 0;
    raf.setPositionSync(start);
    final text = String.fromCharCodes(raf.readSync(len - start));
    final m = RegExp(r'otp-code(?:=22|")?>\s*(\d{6})').allMatches(text).toList();
    return m.isEmpty ? null : m.last.group(1);
  } finally {
    raf.closeSync();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('session: logout, wrong password, login, forgot password',
      (t) async {
    _tester = t;
    assertLocalApi();
    installFakeImagePicker();
    final d = await api.createThrowawayDriver();

    // Put the throwaway on duty (API) so logout's "go off duty" is observable.
    final adminTok = await api.admin;
    final me = await api.call('POST', '/auth/login',
        data: {'email': d.email, 'password': d.password});
    final dToken = me.data['token'] as String;
    final profileId = (me.data['user']['driver_profile']['id'] as num).toInt();
    final att = await api.call('POST', '/drivers/$profileId/duty-attendance',
        token: dToken,
        data: FormDataFactory.photo());
    expect(att.statusCode, 201, reason: 'attendance -> ${att.data}');

    Future<bool> onDuty() async {
      final r = await api.call('GET', '/drivers/$profileId', token: adminTok);
      final v = api.body(r)['is_available'];
      return v == true || v == 1;
    }

    expect(await onDuty(), isTrue);

    await signInRider(t, email: d.email, password: d.password);
    expect(find.byType(RiderMainScreen), findsOneWidget);
    final appToken = await SecureStorageService.getToken();
    expect(appToken, isNotNull);

    await step('logout -> login screen, token cleared + revoked, off duty',
        () async {
      await _logoutViaUi(t);
      await pumpUntil(t, _riderLoginForm, pumps: 80, what: 'rider login form');
      await settle(t, 2000);
      expect(find.byType(RiderMainScreen), findsNothing);
      expect(await SecureStorageService.getToken(), isNull);
      final probe = await api.call('GET', '/auth/me', token: appToken);
      expect(probe.statusCode, 401, reason: 'old token must be revoked');
      expect(await onDuty(), isFalse,
          reason: 'logout must put the rider off duty on the server');
    });

    await step('wrong password shows an error and stays on login', () async {
      await _loginFromStartScreen(t, d.email, 'Not-The-Password1!');
      await settle(t, 3000);
      expect(find.byType(RiderMainScreen), findsNothing);
      expect(find.byKey(const ValueKey('rider_login_form')), findsOneWidget);
      final err = find.textContaining(
          RegExp(r'invalid|incorrect|wrong|credential|not match|failed',
              caseSensitive: false));
      expect(err, findsWidgets, reason: 'an error message must be visible');
      expect(await SecureStorageService.getToken(), isNull);
    });

    await step('login validation: empty form', () async {
      ScaffoldMessenger.of(t.element(find.text('Log In').first)).clearSnackBars();
      await t.pump(const Duration(milliseconds: 600));
      final form = find.byKey(const ValueKey('rider_login_form'));
      final fields =
          find.descendant(of: form, matching: find.byType(TextFormField));
      await t.enterText(fields.at(0), '');
      await t.enterText(fields.at(1), '');
      await _tapClear(t, find.text('Log In'));
      await settle(t, 600);
      expect(find.text('Please enter your email'), findsWidgets);
    });

    await step('correct password logs in again', () async {
      final form = find.byKey(const ValueKey('rider_login_form'));
      final fields =
          find.descendant(of: form, matching: find.byType(TextFormField));
      await t.enterText(fields.at(0), d.email);
      await t.enterText(fields.at(1), d.password);
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await _tapClear(t, find.text('Log In'));
      await pumpUntil(t, find.byType(RiderMainScreen),
          pumps: 200, what: 'RiderMainScreen after re-login');
      expect(await SecureStorageService.getToken(), isNotNull);
    });

    await step('forgot password: validation, OTP, reset, login with new password',
        () async {
      await _logoutViaUi(t);
      await pumpUntil(t, _riderLoginForm, pumps: 80, what: 'rider login form');
      await pumpUntil(t, find.text('Forgot Password?'), what: 'forgot link');
      await t.tap(find.text('Forgot Password?'));
      await pumpUntil(t, find.text('Send OTP'), what: 'forgot screen');

      // Empty + invalid email.
      await _tapClear(t, find.text('Send OTP'));
      await settle(t, 500);
      expect(find.text('Please enter your email'), findsWidgets);
      final emailField = find.byType(TextFormField);
      await t.enterText(emailField.last, 'not-an-email');
      await _tapClear(t, find.text('Send OTP'));
      await settle(t, 500);
      expect(find.text('Please enter a valid email'), findsWidgets);

      // Valid email -> OTP step.
      await t.enterText(emailField.last, d.email);
      await _tapClear(t, find.text('Send OTP'));
      await pumpUntil(t, find.text('Verify OTP'), pumps: 80, what: 'OTP step');

      // OTP validation + wrong code.
      final otpField = find.byType(TextFormField);
      await _tapClear(t, find.text('Verify OTP').last);
      await settle(t, 500);
      expect(find.text('Please enter OTP'), findsWidgets);
      await t.enterText(otpField.last, '123');
      await _tapClear(t, find.text('Verify OTP').last);
      await settle(t, 500);
      expect(find.text('OTP must be 6 digits'), findsWidgets);
      await t.enterText(otpField.last, '000000');
      await _tapClear(t, find.text('Verify OTP').last);
      await settle(t, 2500);
      expect(find.text('Reset Password'), findsNothing,
          reason: 'a wrong OTP must not open the reset step');

      // Real OTP from the backend mail log.
      final otp = await _latestResetOtp();
      if (otp == null) {
        // ignore: avoid_print
        print('NOTE: could not read the OTP from $_logPath; reset skipped');
        return;
      }
      // ignore: avoid_print
      print('forgot-password OTP read from the backend log: $otp');
      await t.enterText(otpField.last, otp);
      await t.pump(const Duration(milliseconds: 300));
      // ignore: avoid_print
      print('OTP field now holds: ${t.widget<TextFormField>(otpField.last).controller?.text}');
      await _tapClear(t, find.text('Verify OTP').last);
      await settle(t, 2500);
      dumpScreen(t, 'after real OTP verify tap');
      await pumpUntil(t, find.text('Confirm Password'),
          pumps: 80, what: 'reset step');
      final pw = find.byType(TextFormField).at(0);
      final cf = find.byType(TextFormField).at(1);
      await t.enterText(pw, 'Newer456!pass');
      await t.enterText(cf, 'Mismatch456!');
      await _tapClear(t, find.text('Reset Password').last);
      await settle(t, 600);
      expect(find.textContaining('match'), findsWidgets);
      await t.enterText(cf, 'Newer456!pass');
      await _tapClear(t, find.text('Reset Password').last);
      await settle(t, 3000);
      d.password = 'Newer456!pass';
      // Old password no longer works, new one does (API).
      final bad = await api.call('POST', '/auth/login',
          data: {'email': d.email, 'password': 'Throwaway123!'});
      expect(bad.statusCode, anyOf(401, 422), reason: 'old password refused');
      final good = await api.call('POST', '/auth/login',
          data: {'email': d.email, 'password': d.password});
      expect(good.statusCode, 200, reason: 'new password accepted');
    });

    expect(failures, isEmpty, reason: 'Failed steps: $failures');
  });

  testWidgets('change password + deactivate account (throwaway)', (t) async {
    _tester = t;
    failures.clear();
    assertLocalApi();
    final d = await api.createThrowawayDriver();
    await signInRider(t, email: d.email, password: d.password);
    expect(find.byType(RiderMainScreen), findsOneWidget);

    await step('change password: wrong current password is refused', () async {
      _nav.pushNamed(MainRoutes.riderChangePassword);
      await pumpUntil(t, find.byType(RiderChangePasswordScreen),
          what: 'change password screen');
      await settle(t, 600);
      final fields = find.descendant(
          of: find.byType(RiderChangePasswordScreen),
          matching: find.byType(TextFormField));
      await t.enterText(fields.at(0), 'WrongCurrent1!');
      await t.enterText(fields.at(1), 'BrandNew789!');
      await t.enterText(fields.at(2), 'BrandNew789!');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pump(const Duration(milliseconds: 300));
      final submit = find.widgetWithText(FilledButton, 'Change Password');
      await t.ensureVisible(submit);
      await t.tap(submit);
      await settle(t, 3000);
      expect(find.byType(RiderChangePasswordScreen), findsOneWidget,
          reason: 'screen stays open on failure');
      final still = await api.call('POST', '/auth/login',
          data: {'email': d.email, 'password': d.password});
      expect(still.statusCode, 200, reason: 'password unchanged');
    });

    await step('change password: valid change works', () async {
      final fields = find.descendant(
          of: find.byType(RiderChangePasswordScreen),
          matching: find.byType(TextFormField));
      await t.enterText(fields.at(0), d.password);
      await t.enterText(fields.at(1), 'BrandNew789!');
      await t.enterText(fields.at(2), 'BrandNew789!');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pump(const Duration(milliseconds: 300));
      final submit = find.widgetWithText(FilledButton, 'Change Password');
      await t.ensureVisible(submit);
      await t.tap(submit);
      await pumpUntilGone(t, find.byType(RiderChangePasswordScreen), pumps: 80);
      final old = await api.call('POST', '/auth/login',
          data: {'email': d.email, 'password': d.password});
      expect(old.statusCode, anyOf(401, 422), reason: 'old password refused');
      d.password = 'BrandNew789!';
      final ok = await api.call('POST', '/auth/login',
          data: {'email': d.email, 'password': d.password});
      expect(ok.statusCode, 200, reason: 'new password accepted');
      // The app session must still be usable (token refreshed, not logged out).
      expect(find.byType(RiderMainScreen), findsOneWidget);
      expect(await SecureStorageService.getToken(), isNotNull);
    });

    await step('deactivate: needs confirmation, wrong password refused',
        () async {
      _nav.pushNamed(MainRoutes.riderDeactivateAccount);
      await pumpUntil(t, find.byType(RiderDeactivateAccountScreen),
          what: 'deactivate screen');
      await settle(t, 600);
      final screen = find.byType(RiderDeactivateAccountScreen);
      final fields =
          find.descendant(of: screen, matching: find.byType(TextFormField));
      final submit = find.widgetWithText(FilledButton, 'Deactivate Account');
      // Without ticking the box nothing is sent.
      await t.enterText(fields.first, d.password);
      await t.ensureVisible(submit);
      await t.tap(submit);
      await settle(t, 800);
      expect(find.text('Please confirm that you understand this action.'),
          findsWidgets);
      // Tick the box, wrong password.
      await t.tap(find.byType(CheckboxListTile));
      await t.pump(const Duration(milliseconds: 300));
      await t.enterText(fields.first, 'WrongPassword1!');
      await t.ensureVisible(submit);
      await t.tap(submit);
      await pumpUntil(t, find.text('Deactivate account?'), what: 'confirm dialog');
      await t.tap(find.widgetWithText(FilledButton, 'Deactivate').last);
      await settle(t, 3000);
      expect(find.byType(RiderDeactivateAccountScreen), findsOneWidget,
          reason: 'wrong password must keep the screen open');
      final stillOk = await api.call('POST', '/auth/login',
          data: {'email': d.email, 'password': d.password});
      expect(stillOk.statusCode, 200, reason: 'account still active');
    });

    await step('deactivate: correct password -> logged out, login refused',
        () async {
      final screen = find.byType(RiderDeactivateAccountScreen);
      final fields =
          find.descendant(of: screen, matching: find.byType(TextFormField));
      await t.enterText(fields.first, d.password);
      final submit = find.widgetWithText(FilledButton, 'Deactivate Account');
      await t.ensureVisible(submit);
      await t.tap(submit);
      await pumpUntil(t, find.text('Deactivate account?'), what: 'confirm dialog');
      await t.tap(find.widgetWithText(FilledButton, 'Deactivate').last);
      await pumpUntil(t, _riderLoginForm, pumps: 120, what: 'login form after deactivate');
      expect(await SecureStorageService.getToken(), isNull);
      final login = await api.call('POST', '/auth/login',
          data: {'email': d.email, 'password': d.password});
      expect(login.statusCode, isNot(200),
          reason: 'deactivated account must not log in: ${login.data}');
      // And through the UI.
      await _loginFromStartScreen(t, d.email, d.password);
      await settle(t, 3000);
      expect(find.byType(RiderMainScreen), findsNothing);
      expect(await SecureStorageService.getToken(), isNull);
    });

    expect(failures, isEmpty, reason: 'Failed steps: $failures');
  });

  testWidgets('delete account permanently (throwaway)', (t) async {
    _tester = t;
    failures.clear();
    assertLocalApi();
    final d = await api.createThrowawayDriver();
    await signInRider(t, email: d.email, password: d.password);
    expect(find.byType(RiderMainScreen), findsOneWidget);

    await step('delete: confirm box, validation, wrong password refused',
        () async {
      _nav.pushNamed(MainRoutes.riderDeleteAccount);
      await pumpUntil(t, find.byType(RiderDeleteAccountScreen),
          what: 'delete screen');
      await settle(t, 600);
      final screen = find.byType(RiderDeleteAccountScreen);
      final fields =
          find.descendant(of: screen, matching: find.byType(TextFormField));
      final submit =
          find.widgetWithText(FilledButton, 'Delete account permanently');
      // 1. Without ticking the confirmation box nothing is sent.
      await t.ensureVisible(submit);
      await t.tap(submit);
      await settle(t, 800);
      expect(find.text('Please confirm that you understand this action is permanent.'),
          findsWidgets);
      // 2. Ticked but empty fields -> field validation.
      await t.tap(find.byType(CheckboxListTile));
      await t.pump(const Duration(milliseconds: 300));
      await t.ensureVisible(submit);
      await t.tap(submit);
      await settle(t, 600);
      expect(find.text('Password is required'), findsWidgets);
      expect(find.text('Type DELETE to confirm'), findsWidgets);
      // 3. Wrong password -> server refuses, screen stays, account intact.
      await t.enterText(fields.at(0), 'WrongPassword1!');
      await t.enterText(fields.at(1), 'DELETE');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pump(const Duration(milliseconds: 300));
      await t.ensureVisible(submit);
      await t.tap(submit);
      await pumpUntil(t, find.text('Delete account permanently?'),
          what: 'confirm dialog');
      await t.tap(find.widgetWithText(FilledButton, 'Delete forever').last);
      await settle(t, 3000);
      expect(find.byType(RiderDeleteAccountScreen), findsOneWidget);
      final ok = await api.call('POST', '/auth/login',
          data: {'email': d.email, 'password': d.password});
      expect(ok.statusCode, 200, reason: 'wrong password must not delete');
    });

    await step('delete: correct password -> account gone, login refused',
        () async {
      final screen = find.byType(RiderDeleteAccountScreen);
      final fields =
          find.descendant(of: screen, matching: find.byType(TextFormField));
      await t.enterText(fields.at(0), d.password);
      await t.enterText(fields.at(1), 'DELETE');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pump(const Duration(milliseconds: 300));
      final submit =
          find.widgetWithText(FilledButton, 'Delete account permanently');
      await t.ensureVisible(submit);
      await t.tap(submit);
      await pumpUntil(t, find.text('Delete account permanently?'),
          what: 'confirm dialog');
      await t.tap(find.widgetWithText(FilledButton, 'Delete forever').last);
      await pumpUntil(t, _riderLoginForm, pumps: 120, what: 'login form after delete');
      expect(await SecureStorageService.getToken(), isNull);
      final login = await api.call('POST', '/auth/login',
          data: {'email': d.email, 'password': d.password});
      expect(login.statusCode, isNot(200),
          reason: 'deleted account must not log in: ${login.data}');
      await _loginFromStartScreen(t, d.email, d.password);
      await settle(t, 3000);
      expect(find.byType(RiderMainScreen), findsNothing);
    });

    expect(failures, isEmpty, reason: 'Failed steps: $failures');
  });

  testWidgets('rider registration screen: terms gate + field validation',
      (t) async {
    _tester = t;
    failures.clear();
    assertLocalApi();
    await RememberMeService.init();
    await RememberMeService.clearSession();
    await SecureStorageService.clearAll();
    await app.main();
    await pumpUntil(t, _loginButton, what: 'start screen');

    await step('terms must be accepted before the form opens', () async {
      NotificationNavigationService.navigatorKey.currentState!
          .pushNamed(RegisterRoutes.riderRegister);
      await pumpUntil(t, find.byType(RegisterInfoScreen), what: 'register screen');
      await settle(t, 1200);
      // Continue is disabled until the terms box is ticked.
      final cont = find.widgetWithText(PrimaryButton, 'Continue');
      await pumpUntil(t, cont, what: 'terms Continue button');
      expect(t.widget<PrimaryButton>(cont).onPressed, isNull);
      await t.tap(find.byType(Checkbox).first);
      await t.pump(const Duration(milliseconds: 400));
      expect(t.widget<PrimaryButton>(cont).onPressed, isNotNull);
      await t.tap(cont);
      await pumpUntil(t, find.text('First Name'), what: 'registration form');
    });

    await step('empty submit shows every required-field error, sends nothing',
        () async {
      final submit = find.widgetWithText(PrimaryButton, 'Continue to payment');
      await t.scrollUntilVisible(submit, 300,
          scrollable: find.byType(Scrollable).first, maxScrolls: 60);
      await t.tap(submit);
      await settle(t, 800);
      expect(find.text('First name is required'), findsWidgets);
      expect(find.text('Last name is required'), findsWidgets);
      expect(find.text('Email is required'), findsWidgets);
      expect(find.text('Password is required'), findsWidgets);
      expect(find.text('Driver license number is required'), findsWidgets);
      noErrors(t, 'registration validation');
    });

    await step('bad email / short password / mismatch are rejected', () async {
      final fields = find.byType(TextFormField);
      expect(fields, findsWidgets);
      // Fill by label order: first, last, birthday, email, phone, pw, confirm, license.
      final f = fields.evaluate().toList();
      Future<void> type(int i, String v) async {
        final w = find.byWidget(f[i].widget);
        await t.ensureVisible(w);
        await t.enterText(w, v);
      }
      await type(0, 'A');
      await type(3, 'not-an-email');
      await type(5, 'short');
      await type(6, 'different');
      await t.pump(const Duration(milliseconds: 500));
      final submit = find.widgetWithText(PrimaryButton, 'Continue to payment');
      await t.ensureVisible(submit);
      await t.tap(submit);
      await settle(t, 800);
      expect(find.text('First name must be at least 2 characters'), findsWidgets);
      expect(find.text('Please enter a valid email address'), findsWidgets);
      expect(find.text('Password must be at least 8 characters'), findsWidgets);
      expect(find.text('Passwords do not match'), findsWidgets);
      // Nothing was registered server-side by these attempts.
      final r = await api.call('POST', '/auth/login',
          data: {'email': 'not-an-email', 'password': 'short'});
      expect(r.statusCode, isNot(200));
      noErrors(t, 'registration validation 2');
    });

    expect(failures, isEmpty, reason: 'Failed steps: $failures');
  });
}

/// Builds the multipart body for the attendance photo upload.
class FormDataFactory {
  static Object photo() => E2eApi.photoForm();
}
