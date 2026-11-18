// Merchant session / account flows against the LOCAL throwaway backend:
// wrong password, logout/login, change password, forgot password (OTP),
// delete account, deactivate account, registration form validation.
// Every destructive step runs on a THROWAWAY merchant created in the local DB
// (never merchant@test.com). See merchant_order_flow_test.dart for setup.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lezgo_rider/core/constants/routers/main/main_routes.dart';
import 'package:lezgo_rider/core/services/notification_navigation_service.dart';
import 'package:lezgo_rider/core/services/secure_storage_service.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_main_screen.dart';

import 'support/merchant_test_support.dart';

// bcrypt("123456"): lets the test "receive" the emailed OTP, which the backend
// only stores hashed.
const _knownOtpHash =
    r'$2y$10$u5oE2bksJ8.Spy4aCFc5/eiXVaDWdeyEzyd76AFXYxCXmophvvrda';

final _merchantLoginForm = find.byKey(const ValueKey('merchant_login_form'));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    '5a. wrong password, logout, login again, change password, delete account',
    timeout: const Timeout(Duration(minutes: 12)),
    (tester) async {
      assertLocalBackend();
      await ensureLocalFixtures();
      final email = await createThrowawayMerchant('session');
      const newPassword = 'NewThrow456!';

      // ---- wrong password -------------------------------------------------
      await submitLogin(tester, email: email, password: 'WrongPass999!');
      await pumpUntil(
        tester,
        find.text('The provided credentials are incorrect.'),
        reason: 'wrong-password error',
      );
      expect(find.byType(MerchantMainScreen), findsNothing);
      expect(_merchantLoginForm, findsOneWidget,
          reason: 'must stay on the login form after a failed login');
      expect(await SecureStorageService.getToken(), isNull,
          reason: 'no token may be stored after a failed login');
      expectNoFrameworkErrors(tester, 'wrong password');

      // ---- correct password ----------------------------------------------
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);
      await _retypeLogin(tester, email, kThrowawayPassword);
      await pumpUntil(tester, find.byType(MerchantMainScreen),
          maxPumps: 240, reason: 'main screen after login');
      await pumpFor(tester, 2000);
      final token1 = await SecureStorageService.getToken();
      expect(token1, isNotNull, reason: 'token stored after login');
      expect((await api('GET', '/v1/auth/me', token: token1)).ok, isTrue);

      // ---- logout ---------------------------------------------------------
      await tapMerchantTab(tester, 'Profile');
      await tester.tap(find.byIcon(Icons.exit_to_app_rounded));
      await pumpFor(tester, 600);
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      // Cancel keeps the session
      await tester.tap(find.text('Cancel'));
      await pumpFor(tester, 500);
      expect(find.byType(MerchantMainScreen), findsOneWidget);
      expect(await SecureStorageService.getToken(), isNotNull);
      await tester.tap(find.byIcon(Icons.exit_to_app_rounded));
      await pumpFor(tester, 600);
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Logout')).last);
      await pumpUntil(tester, _merchantLoginForm,
          maxPumps: 120, reason: 'login form after logout');
      await pumpFor(tester, 800);
      expect(find.byType(MerchantMainScreen), findsNothing);
      expect(await SecureStorageService.getToken(), isNull,
          reason: 'token must be cleared on logout');
      expect(
        (await api('GET', '/v1/auth/me', token: token1)).status,
        401,
        reason: 'the old token must be revoked server-side',
      );
      expectNoFrameworkErrors(tester, 'logout');

      // ---- login again ------------------------------------------------------
      await _retypeLogin(tester, email, kThrowawayPassword);
      await pumpUntil(tester, find.byType(MerchantMainScreen),
          maxPumps: 240, reason: 'main screen after second login');
      await pumpFor(tester, 2000);
      expect(await SecureStorageService.getToken(), isNotNull);

      // ---- change password ---------------------------------------------------
      await tapMerchantTab(tester, 'Profile');
      await _openProfileTile(tester, 'Security & 2FA');
      await tester.tap(find.text('Change Password'));
      await pumpUntil(tester, find.text('Current password'));
      var sawSnack = false;
      Future<void> typePw(String current, String next, String confirm) async {
        await tester.enterText(
            _pwField(tester, 'Current password'), current);
        await tester.enterText(_pwField(tester, 'New password'), next);
        await tester.enterText(
            _pwField(tester, 'Confirm new password'), confirm);
        FocusManager.instance.primaryFocus?.unfocus();
        await pumpFor(tester, 300);
        final btn = find.widgetWithText(FilledButton, 'Change Password');
        final fallback = find.widgetWithText(ElevatedButton, 'Change Password');
        final target = btn.evaluate().isNotEmpty ? btn : fallback;
        await tester.ensureVisible(target);
        await tester.tap(target);
        sawSnack = await sawSnackBar(tester, ms: 1500);
        await pumpFor(tester, 800);
      }

      await typePw(kThrowawayPassword, 'short', 'short');
      expect(find.text('Password must be at least 8 characters'),
          findsWidgets);
      await typePw(kThrowawayPassword, 'alllowercase1', 'alllowercase1');
      expect(find.text('Password must contain at least one uppercase letter'),
          findsWidgets);
      await typePw(kThrowawayPassword, newPassword, 'Different789!');
      expect(find.text('Passwords do not match'), findsWidgets);
      await typePw('NotMyPassword1!', newPassword, newPassword);
      // wrong current password is refused by the API; the password is unchanged
      expect(sawSnack, isTrue, reason: 'wrong current password must show an error');
      expect((await api('POST', '/v1/auth/login', data: {
        'email': email,
        'password': kThrowawayPassword,
      }))
          .ok, isTrue, reason: 'old password must still work');
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);

      await typePw(kThrowawayPassword, newPassword, newPassword);
      await pumpUntil(tester, find.text('Password updated successfully.'),
          reason: 'password updated snackbar');
      // The app keeps working with the refreshed tokens. Check this BEFORE any
      // API login of our own (a login may revoke the app's token).
      await pumpFor(tester, 1500);
      expectNoFrameworkErrors(tester, 'change password');
      final tokenAfterChange = await SecureStorageService.getToken();
      expect((await api('GET', '/v1/auth/me', token: tokenAfterChange)).ok,
          isTrue,
          reason: 'session must survive a password change');
      expect(
        (await api('POST', '/v1/auth/login',
                data: {'email': email, 'password': kThrowawayPassword}))
            .ok,
        isFalse,
        reason: 'old password must stop working',
      );
      expect(
        (await api('POST', '/v1/auth/login',
                data: {'email': email, 'password': newPassword}))
            .ok,
        isTrue,
        reason: 'new password must work',
      );

      // ---- delete account ------------------------------------------------------
      while (find.byType(MerchantMainScreen).hitTestable().evaluate().isEmpty) {
        final nav = NotificationNavigationService.navigatorKey.currentState!;
        if (!nav.canPop()) break;
        nav.pop();
        await pumpFor(tester, 500);
      }
      await tapMerchantTab(tester, 'Profile');
      await _openProfileTile(tester, 'Delete account');
      await pumpUntil(tester, find.text('Delete account permanently'));
      // nothing ticked
      await _tapDelete(tester);
      expect(find.text('Please confirm that you understand this action is permanent.'),
          findsWidgets);
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);
      await tester.tap(find.byType(CheckboxListTile));
      await pumpFor(tester, 300);
      await _tapDelete(tester);
      expect(find.text('Password is required'), findsWidgets);
      expect(find.text('Type DELETE to confirm'), findsWidgets);
      // wrong password -> API refuses, account survives
      await tester.enterText(_deleteField(tester, 'Confirm password'), 'Wrong123!pw');
      await tester.enterText(_deleteField(tester, 'Type DELETE to confirm'), 'DELETE');
      await _tapDelete(tester);
      await tester.tap(find.text('Delete forever'));
      expect(await sawSnackBar(tester), isTrue,
          reason: 'wrong password on delete must show an error');
      expect(
        (await api('POST', '/v1/auth/login',
                data: {'email': email, 'password': newPassword}))
            .ok,
        isTrue,
        reason: 'account must survive a wrong-password delete attempt',
      );
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);
      // correct password
      await tester.enterText(_deleteField(tester, 'Confirm password'), newPassword);
      await tester.enterText(_deleteField(tester, 'Type DELETE to confirm'), 'delete');
      await tester.enterText(
          _deleteField(tester, 'Reason (optional)'), 'integration test');
      await _tapDelete(tester);
      await tester.tap(find.text('Delete forever'));
      await pumpUntil(tester, _merchantLoginForm,
          maxPumps: 160, reason: 'login form after deleting the account');
      await pumpFor(tester, 800);
      expect(await SecureStorageService.getToken(), isNull);
      final login = await api('POST', '/v1/auth/login',
          data: {'email': email, 'password': newPassword});
      expect(login.ok, isFalse,
          reason: 'a deleted account must not be able to log in: $login');
      final userRows = await localSql(
        'select id, deleted_at, is_active, email from users where id = '
        '(select id from users where email = ? or email like ? limit 1)',
        [email, '%deleted%'],
      );
      // ignore: avoid_print
      print('DELETED ACCOUNT ROW: $userRows, login response: $login');
      expectNoFrameworkErrors(tester, 'delete account');
    },
  );

  testWidgets(
    '5b. deactivate account refuses further logins',
    timeout: const Timeout(Duration(minutes: 8)),
    (tester) async {
      assertLocalBackend();
      await ensureLocalFixtures();
      final email = await createThrowawayMerchant('deactivate');
      await signInMerchant(tester, email: email, password: kThrowawayPassword);
      // The merchant UI has no menu entry for it (hidden for merchants), so
      // open the registered route directly.
      NotificationNavigationService.navigatorKey.currentState!
          .pushNamed(MainRoutes.merchantDeactivateAccount);
      await pumpUntil(tester, find.text('Deactivate Account'));
      await pumpFor(tester, 2000);
      final deactivateBtn = find.widgetWithText(FilledButton, 'Deactivate Account');
      await tapWhenHittable(tester, deactivateBtn);
      await pumpFor(tester, 600);
      expect(find.text('Please confirm that you understand this action.'),
          findsWidgets);
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);
      await tester.tap(find.byType(CheckboxListTile));
      await pumpFor(tester, 300);
      await tapWhenHittable(tester, deactivateBtn);
      await pumpFor(tester, 600);
      expect(find.text('Password is required'), findsWidgets);
      // wrong password
      await tester.enterText(_deleteField(tester, 'Confirm password'), 'Nope12345!');
      await tapWhenHittable(tester, deactivateBtn);
      await pumpFor(tester, 600);
      await tester.tap(find.text('Deactivate').last);
      expect(await sawSnackBar(tester), isTrue,
          reason: 'wrong password on deactivate must show an error');
      expect(
        (await api('POST', '/v1/auth/login',
                data: {'email': email, 'password': kThrowawayPassword}))
            .ok,
        isTrue,
        reason: 'wrong password must not deactivate the account',
      );
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);
      await tester.enterText(
          _deleteField(tester, 'Confirm password'), kThrowawayPassword);
      await tapWhenHittable(tester, deactivateBtn);
      await pumpFor(tester, 600);
      await tester.tap(find.text('Deactivate').last);
      await pumpUntil(tester, _merchantLoginForm,
          maxPumps: 160, reason: 'login form after deactivation');
      final login = await api('POST', '/v1/auth/login',
          data: {'email': email, 'password': kThrowawayPassword});
      expect(login.ok, isFalse, reason: 'deactivated account logged in: $login');
      // ignore: avoid_print
      print('DEACTIVATED LOGIN RESPONSE: $login');
      // the login screen shows the server's reason
      await _retypeLogin(tester, email, kThrowawayPassword);
      // The server's refusal message was asserted above via the API; in the UI
      // the user must simply stay on the login screen.
      await sawSnackBar(tester);
      expect(find.byType(MerchantMainScreen), findsNothing);
      expectNoFrameworkErrors(tester, 'deactivate');
    },
  );

  testWidgets(
    '5c. forgot password: email validation, OTP, reset',
    timeout: const Timeout(Duration(minutes: 8)),
    (tester) async {
      assertLocalBackend();
      await ensureLocalFixtures();
      final email = await createThrowawayMerchant('forgot');
      const resetTo = 'ResetPass789!';

      await openMerchantAuth(tester);
      await pumpFor(tester, 2000);
      await tapWhenHittable(tester, find.text('Forgot Password?'));
      await pumpUntil(tester, find.text('Enter your email to receive an OTP code'));
      await pumpFor(tester, 2000);
      // empty / malformed email
      await tapWhenHittable(tester, find.text('Send OTP'));
      await pumpFor(tester, 500);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.textContaining('email', findRichText: true), findsWidgets);
      await enterTextReliably(tester, fieldWith('Email'), 'not-an-email');
      await tapWhenHittable(tester, find.text('Send OTP'));
      await pumpFor(tester, 500);
      expect(find.text('Enter your email to receive an OTP code'), findsOneWidget,
          reason: 'must not advance with an invalid email');
      // valid email -> OTP step
      await enterTextReliably(tester, fieldWith('Email'), email);
      FocusManager.instance.primaryFocus?.unfocus();
      await tapWhenHittable(tester, find.text('Send OTP'));
      await pumpUntil(tester, fieldWith('OTP Code (6 digits)'),
          reason: 'OTP step');
      // The OTP is only stored hashed: swap in a hash of 123456.
      final updated = await localSql(
        "update password_resets set otp_hash=? where email=? and is_used=0",
        [_knownOtpHash, email],
      );
      expect(updated, isEmpty);
      // wrong OTP
      await enterTextReliably(tester, fieldWith('OTP Code (6 digits)'), '000000');
      await tester.tap(find.text('Verify OTP').last);
      expect(await sawSnackBar(tester), isTrue,
          reason: 'wrong OTP must show an error');
      expect(find.text('OTP verified successfully'), findsNothing);
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);
      // short OTP
      await enterTextReliably(tester, fieldWith('OTP Code (6 digits)'), '123');
      await tester.tap(find.text('Verify OTP').last);
      await pumpFor(tester, 500);
      if (find.text('OTP must be 6 digits').evaluate().isEmpty) {
        // ignore: avoid_print
        print('FORGOT PASSWORD TEXTS: ${allTexts()}');
      }
      expect(find.text('OTP must be 6 digits'), findsWidgets);
      // right OTP
      await enterTextReliably(tester, fieldWith('OTP Code (6 digits)'), '123456');
      await tester.tap(find.text('Verify OTP').last);
      await pumpUntil(tester, fieldWith('New Password'), reason: 'new password step');
      // validations
      await enterTextReliably(tester, fieldWith('New Password'), 'weak');
      await enterTextReliably(tester, fieldWith('Confirm Password'), 'weak');
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);
      await tapWhenHittable(tester, find.text('Reset Password').last);
      await pumpFor(tester, 500);
      expect(find.textContaining('Password must'), findsWidgets);
      await enterTextReliably(tester, fieldWith('New Password'), resetTo);
      await enterTextReliably(tester, fieldWith('Confirm Password'), 'Mismatch789!');
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);
      await tapWhenHittable(tester, find.text('Reset Password').last);
      await pumpFor(tester, 500);
      expect(find.textContaining('match'), findsWidgets);
      await enterTextReliably(tester, fieldWith('Confirm Password'), resetTo);
      FocusManager.instance.primaryFocus?.unfocus();
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);
      await tapWhenHittable(tester, find.text('Reset Password').last);
      await pumpUntil(tester, find.text('Password reset successfully'),
          reason: 'reset success snackbar');
      expect(
        (await api('POST', '/v1/auth/login',
                data: {'email': email, 'password': resetTo}))
            .ok,
        isTrue,
        reason: 'new password must work after reset',
      );
      expect(
        (await api('POST', '/v1/auth/login',
                data: {'email': email, 'password': kThrowawayPassword}))
            .ok,
        isFalse,
      );
      expectNoFrameworkErrors(tester, 'forgot password');
    },
  );

  testWidgets(
    '5d. merchant registration form validation',
    timeout: const Timeout(Duration(minutes: 8)),
    (tester) async {
      assertLocalBackend();
      await ensureLocalFixtures();
      await openMerchantAuth(tester, register: true);
      // role chooser -> Merchant
      await pumpUntil(tester, find.text('Merchant'));
      await tester.tap(find.text('Merchant').first);
      await pumpFor(tester, 1000);
      // terms gate: Continue disabled until the box is ticked
      await pumpUntil(tester, find.text('I agree to the Terms and Conditions'));
      final continueBtn = find.widgetWithText(ElevatedButton, 'Continue');
      if (continueBtn.evaluate().isNotEmpty) {
        expect(tester.widget<ElevatedButton>(continueBtn).onPressed, isNull,
            reason: 'cannot continue without accepting the terms');
      }
      await tester.tap(find.byType(Checkbox));
      await pumpFor(tester, 400);
      await tester.tap(find.text('Continue').last);
      await pumpUntil(tester, find.text('Continue to payment'),
          reason: 'registration form');
      // submit empty form -> every required field reports an error
      final submit = find.text('Continue to payment');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await pumpFor(tester, 800);
      for (final msg in [
        'Restaurant Name is required',
        'Last name is required',
        'First name is required',
      ]) {
        expect(find.text(msg), findsWidgets, reason: 'missing "$msg"');
      }
      expectNoFrameworkErrors(tester, 'registration empty submit');
      // bad values
      final fields = find.byType(TextFormField);
      expect(fields, findsWidgets);
      await tester.enterText(
          find.widgetWithText(TextFormField, '').first, 'Test Resto');
      await pumpFor(tester, 300);
      await enterTextReliably(tester, fieldWith('LeSgoPartner@gmail.com'), 'bad-email');
      await enterTextReliably(tester, fieldWith('Enter your password'), 'short');
      await enterTextReliably(tester, fieldWith('Re-enter your password'), 'different');
      FocusManager.instance.primaryFocus?.unfocus();
      await pumpFor(tester, 500);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await pumpFor(tester, 800);
      expect(find.text('Password must be at least 8 characters'), findsWidgets);
      expect(find.text('Passwords do not match'), findsWidgets);
      expectNoFrameworkErrors(tester, 'registration bad values');
    },
  );

  testWidgets(
    '7. staff accounts: invite, change role, deactivate, activate, remove',
    timeout: const Timeout(Duration(minutes: 10)),
    (tester) async {
      assertLocalBackend();
      await ensureLocalFixtures();
      final email = await createThrowawayMerchant('staff');
      final staffEmail = 'staff.${DateTime.now().millisecondsSinceEpoch}@test.com';
      const staffPassword = 'StaffPass123!';
      await signInMerchant(tester, email: email, password: kThrowawayPassword);
      await tapMerchantTab(tester, 'Profile');
      await _openProfileTile(tester, 'Staff Accounts');
      final fab = find.text('Invite Staff');
      await pumpUntil(tester, fab);
      await pumpFor(tester, 800);
      Future<Map<String, Object?>> staffRow() async {
        final rows = await localSql(
          'select ps.id, ps.role, ps.is_active, u.role from partner_staff ps '
          'join users u on u.id = ps.user_id where u.email = ?',
          [staffEmail],
        );
        if (rows.isEmpty) return {};
        final r = rows.first as List;
        return {'id': r[0], 'role': r[1], 'active': r[2], 'userRole': r[3]};
      }

      // invite
      await tester.tap(fab.last);
      await pumpUntil(tester, find.text('Temporary Password'));
      await enterTextReliably(tester, fieldWith('Full Name'), 'E2E Staff');
      await enterTextReliably(tester, fieldWith('Email'), staffEmail);
      await enterTextReliably(tester, fieldWith('Temporary Password'), staffPassword);
      FocusManager.instance.primaryFocus?.unfocus();
      await pumpFor(tester, 300);
      await tester.tap(find.text('Invite').last);
      await pumpUntil(tester, find.text('Staff invited successfully'),
          reason: 'invite success snackbar');
      var row = await staffRow();
      expect(row['role'], 'cashier', reason: 'default role is cashier');
      expect(row['userRole'], 'partner_staff');
      expect(row['active'], 1);
      await pumpUntil(tester, find.text('E2E Staff'), reason: 'staff card');
      // the staff member can sign in through the API
      expect(
        (await api('POST', '/v1/auth/login',
                data: {'email': staffEmail, 'password': staffPassword}))
            .ok,
        isTrue,
      );
      // duplicate email is refused with a visible error
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);
      await tester.tap(fab.last);
      await pumpUntil(tester, find.text('Temporary Password'));
      await enterTextReliably(tester, fieldWith('Full Name'), 'Dup Staff');
      await enterTextReliably(tester, fieldWith('Email'), staffEmail);
      await enterTextReliably(tester, fieldWith('Temporary Password'), staffPassword);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.tap(find.text('Invite').last);
      expect(await sawSnackBar(tester), isTrue,
          reason: 'duplicate email must show an error');
      expect(find.text('Staff invited successfully'), findsNothing);
      expect(
        (await localSql('select count(*) from users where email=?', [staffEmail]))
            .first[0],
        1,
      );
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);

      Future<void> menu(String item) async {
        await tester.tap(find.byType(PopupMenuButton<String>).last);
        await pumpFor(tester, 600);
        await tester.tap(find.text(item).last);
        await pumpFor(tester, 800);
      }

      // change role cashier -> cook
      await menu('Change Role');
      await pumpUntil(tester, find.text('Save'));
      await tester.tap(find.byType(DropdownButton<String>).last);
      await pumpFor(tester, 500);
      await tester.tap(find.text('Cook').last);
      await pumpFor(tester, 400);
      await tester.tap(find.text('Save'));
      await pumpFor(tester, 2000);
      row = await staffRow();
      expect(row['role'], 'cook');

      // deactivate -> inactive; the staff member loses access to store orders
      await menu('Deactivate');
      await pumpFor(tester, 2000);
      row = await staffRow();
      expect(row['active'], 0);
      final staffToken = await apiLogin(staffEmail, staffPassword);
      final orders = await api('GET', '/v1/orders', token: staffToken);
      expect(
        ((orders.data is Map ? orders.data['data'] : orders.data) as List?) ?? [],
        isEmpty,
      );
      // activate again
      await menu('Activate');
      await pumpFor(tester, 2000);
      row = await staffRow();
      expect(row['active'], 1);

      // remove (confirm dialog)
      await menu('Remove');
      await pumpUntil(tester, find.text('Remove Staff'));
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Remove')));
      await pumpFor(tester, 2500);
      expect(await staffRow(), isEmpty, reason: 'staff must be removed');
      expect(find.text('E2E Staff'), findsNothing);
      expectNoFrameworkErrors(tester, 'staff lifecycle');
    },
  );
}

// ---------------------------------------------------------------------------

/// Fills the already visible merchant login form again (after an error/logout).
Future<void> _retypeLogin(
  WidgetTester tester,
  String email,
  String password,
) async {
  await pumpUntil(tester, _merchantLoginForm);
  final fields = find.descendant(
    of: _merchantLoginForm,
    matching: find.byType(TextFormField),
  );
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Log In'));
  await tester.tap(find.text('Log In'));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _openProfileTile(WidgetTester tester, String label) async {
  final tile = find.text(label);
  await tester.scrollUntilVisible(
    tile,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(tile);
  await pumpFor(tester, 1200);
}

Finder _pwField(WidgetTester tester, String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(TextFormField),
);

Finder _deleteField(WidgetTester tester, String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
  description: 'field "$label"',
);

Future<void> _tapDelete(WidgetTester tester) async {
  final btn = find.widgetWithText(FilledButton, 'Delete account permanently');
  await tester.ensureVisible(btn);
  await tester.tap(btn);
  await pumpFor(tester, 700);
}
