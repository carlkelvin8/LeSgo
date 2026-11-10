import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lezgo_rider/core/constants/routers/main/main_routes.dart';
import 'package:lezgo_rider/core/services/remember_me_service.dart';
import 'package:lezgo_rider/core/services/secure_storage_service.dart';
import 'package:lezgo_rider/core/utils/app_localization.dart';
import 'package:lezgo_rider/main.dart' as app;
import 'package:lezgo_rider/core/services/notification_navigation_service.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_change_password_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_customer_service_chat_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_edit_profile_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_faqs_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_main_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_notification_settings_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_payout_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_schedule_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_vehicle_management_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_wallet_history_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_bookings_view.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_history_view.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_more_view.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_profile_view.dart';
import 'package:lezgo_rider/presentation/screens/registration_fee_screen.dart';
import 'package:lezgo_rider/presentation/widgets/main/riderside/rider_bottom_nav_bar.dart';

const _riderEmail = String.fromEnvironment('LES_GO_TEST_RIDER_EMAIL');
const _riderPassword = String.fromEnvironment('LES_GO_TEST_RIDER_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rider forms and settings flows', (tester) async {
    expect(_riderEmail, isNotEmpty);
    expect(_riderPassword, isNotEmpty);
    await _signIn(
      tester,
      accountType: 'rider',
      email: _riderEmail,
      password: _riderPassword,
      landingScreens: [
        find.byType(RiderMainScreen),
        find.byType(RegistrationFeeScreen),
      ],
    );
    expect(find.byType(RiderMainScreen), findsOneWidget,
        reason: 'Rider landed on the fee screen, cannot run rider flows.');
    _t = tester;
    _recover = () {};
    await tester.pump(const Duration(seconds: 2));

    await _step('bookings list/map toggle', () => _bookings(tester));
    await _step('history filters + detail', () => _history(tester));
    await _step('change password validation', () => _changePassword(tester));
    await _step('edit profile validation', () => _editProfile(tester));
    await _step('vehicle management', () => _vehicles(tester));
    await _step('language toggle', () => _language(tester));
    await _step('dark mode toggle', () => _darkMode(tester));
    await _step('faqs', () => _faqs(tester));
    await _step('notification settings', () => _notifSettings(tester));
    await _step('schedule', () => _schedule(tester));
    await _step('wallet history/payout/top-up validation',
        () => _wallet(tester));
    await _step('customer service chat', () => _csChat(tester));
    expect(_failures, isEmpty, reason: 'Failed steps: $_failures');
  });
}

final _failures = <String>[];

Future<void> _step(String name, Future<void> Function() body) async {
  // ignore: avoid_print
  print('=== STEP: $name');
  await _recoverToMain();
  try {
    await body();
    // ignore: avoid_print
    print('=== PASS: $name');
  } catch (e, st) {
    // ignore: avoid_print
    print('=== FAIL: $name -> $e\n$st');
    _failures.add(name);
    _recover?.call();
    await _recoverToMain();
  }
}

VoidCallback? _recover;
WidgetTester? _t;

/// After a failed step: pop screens (with real pumps) until the nav bar shows.
Future<void> _recoverToMain() async {
  final t = _t;
  if (t == null) return;
  for (var i = 0; i < 6; i++) {
    for (var k = 0; k < 4; k++) {
      await t.pump(const Duration(milliseconds: 300));
    }
    if (find.byType(RiderBottomNavBar).hitTestable().evaluate().isNotEmpty) {
      return;
    }
    final nav = NotificationNavigationService.navigatorKey.currentState!;
    if (!nav.canPop()) return;
    nav.pop();
  }
}

NavigatorState _nav(WidgetTester tester) =>
    NotificationNavigationService.navigatorKey.currentState!;

Future<void> _pushNamed(WidgetTester tester, String route, Finder expected) async {
  _nav(tester).pushNamed(route);
  await _pumpUntil(tester, expected);
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _pop(WidgetTester tester) async {
  _nav(tester).pop();
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _scrollFind(WidgetTester tester, Type view, Finder target) async {
  if (target.hitTestable().evaluate().isNotEmpty) return;
  final scrollableFinder =
      find.descendant(of: find.byType(view), matching: find.byType(Scrollable));
  await _pumpUntil(tester, scrollableFinder);
  final scrollable = scrollableFinder.first;
  await tester.scrollUntilVisible(
    target,
    250,
    scrollable: scrollable,
    maxScrolls: 40,
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tapRiderTab(WidgetTester tester, String label) async {
  final tab = find
      .descendant(
        of: find.byType(RiderBottomNavBar),
        matching: find.text(label),
      )
      .hitTestable();
  expect(tab, findsOneWidget, reason: 'Missing rider tab: $label');
  await tester.tap(tab);
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final f = find.text(text).hitTestable();
  if (f.evaluate().isEmpty) {
    await tester.ensureVisible(find.text(text).last);
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.tap(find.text(text).last);
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _bookings(WidgetTester tester) async {
  await _tapRiderTab(tester, 'Bookings');
  expect(find.byType(RiderBookingsView), findsOneWidget);
  final mapView = find.text('Map View');
  if (mapView.evaluate().isNotEmpty) {
    await tester.tap(mapView.first);
    await tester.pump(const Duration(milliseconds: 800));
    final list = find.text('List View');
    expect(list, findsWidgets);
    await tester.tap(list.first);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(RiderBookingsView), findsOneWidget);
  }
}

Future<void> _history(WidgetTester tester) async {
  await _tapRiderTab(tester, 'History');
  expect(find.byType(RiderHistoryView), findsOneWidget);
  await tester.pump(const Duration(seconds: 2));
  for (final filter in ['All', 'Completed', 'Processing', 'Cancelled']) {
    final chip = find.text(filter);
    if (chip.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(tester.element(chip.last), alignment: 0.5);
      await tester.tap(chip.last, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    }
  }
  final all = find.text('All');
  if (all.evaluate().isNotEmpty) {
    await tester.tap(all.last, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
  }
  // Open the first history card if any exist.
  final cards = find.descendant(
    of: find.byType(RiderHistoryView),
    matching: find.byType(InkWell),
  );
  final before = Navigator.of(tester.element(find.byType(RiderMainScreen, skipOffstage: false)));
  if (cards.evaluate().isNotEmpty) {
    for (final c in cards.evaluate().take(6)) {
      final w = find.byElementPredicate((e) => e == c);
      if (!w.hitTestable().evaluate().isNotEmpty) continue;
      await tester.tap(w, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 800));
      if (find.byType(RiderHistoryView).hitTestable().evaluate().isEmpty) {
        // A detail screen opened.
        // ignore: avoid_print
        print('history detail opened');
        before.pop();
        await tester.pump(const Duration(milliseconds: 500));
        break;
      }
    }
  } else {
    // ignore: avoid_print
    print('no history cards present');
  }
  expect(find.byType(RiderMainScreen), findsOneWidget);
}

Future<void> _changePassword(WidgetTester tester) async {
  await _tapRiderTab(tester, 'Profile');
  await _pumpUntil(tester, find.byType(RiderProfileView));
  final row = find.text('Change Password');
  await _scrollFind(tester, RiderProfileView, row);
  await tester.tap(row.last);
  await _pumpUntil(tester, find.byType(RiderChangePasswordScreen));
  await tester.pump(const Duration(milliseconds: 500));
  final fields = find.descendant(
    of: find.byType(RiderChangePasswordScreen),
    matching: find.byType(TextFormField),
  );
  expect(fields, findsNWidgets(3));
  final submit = find.widgetWithText(FilledButton, 'Change Password');
  Future<void> submitForm() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump(const Duration(milliseconds: 400));
  }

  // Empty.
  await submitForm();
  expect(find.textContaining('is required'), findsOneWidget);
  expect(find.text('Please enter your password'), findsWidgets);

  // Mismatched.
  await tester.enterText(fields.at(0), 'TestRider123!');
  await tester.enterText(fields.at(1), 'NewPassw0rd!x');
  await tester.enterText(fields.at(2), 'Different1!x');
  await submitForm();
  expect(find.text('Passwords do not match'), findsOneWidget);

  // Too short.
  await tester.enterText(fields.at(1), 'Ab1!');
  await tester.enterText(fields.at(2), 'Ab1!');
  await submitForm();
  expect(find.text('Password must be at least 8 characters'), findsWidgets);

  // Leave without submitting a valid change.
  await _pop(tester);
  expect(find.byType(RiderChangePasswordScreen), findsNothing);
}

Future<void> _editProfile(WidgetTester tester) async {
  await _tapRiderTab(tester, 'Profile');
  final edit = find.text('Edit Profile');
  // The previous step scrolled the profile down; the header (with the Edit
  // Profile button) is lazily built, so scroll back to the top first.
  final profileScroll = find.descendant(
    of: find.byType(RiderProfileView),
    matching: find.byType(Scrollable),
  );
  await _pumpUntil(tester, profileScroll);
  for (var i = 0; i < 6 && edit.evaluate().isEmpty; i++) {
    await tester.drag(profileScroll.first, const Offset(0, 500));
    await tester.pump(const Duration(milliseconds: 300));
  }
  await _pumpUntil(tester, edit);
  await _scrollFind(tester, RiderProfileView, edit);
  await tester.tap(edit.last);
  await _pumpUntil(tester, find.byType(RiderEditProfileScreen));
  await tester.pump(const Duration(seconds: 1));
  final fields = find.descendant(
    of: find.byType(RiderEditProfileScreen),
    matching: find.byType(TextFormField),
  );
  expect(fields.evaluate().length, greaterThanOrEqualTo(3));
  // Invalid values in memory only; never save.
  await tester.enterText(fields.at(0), '');
  await tester.enterText(fields.at(1), 'abc');
  await tester.pump(const Duration(milliseconds: 200));
  final form = tester.state<FormState>(
    find
        .descendant(
          of: find.byType(RiderEditProfileScreen),
          matching: find.byType(Form),
        )
        .first,
  );
  expect(form.validate(), isFalse);
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('Full name is required'), findsNothing,
      reason: 'sanity: unknown key text should not be literal');
  await _pop(tester);
  expect(find.byType(RiderEditProfileScreen), findsNothing);
}

Future<void> _openMore(WidgetTester tester) async {
  await _tapRiderTab(tester, 'More');
  await _pumpUntil(tester, find.byType(RiderMoreView));
}

Future<void> _openMoreRow(
  WidgetTester tester,
  String label,
  Finder expected,
) async {
  await _openMore(tester);
  final row = find.text(label);
  await _scrollFind(tester, RiderMoreView, row);
  await tester.tap(row.last);
  await _pumpUntil(tester, expected);
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _vehicles(WidgetTester tester) async {
  await _openMoreRow(
    tester,
    'My Vehicles',
    find.byType(RiderVehicleManagementScreen),
  );
  await tester.pump(const Duration(seconds: 2));
  final add = find.text('Add Vehicle');
  expect(add, findsWidgets);
  await tester.ensureVisible(add.last);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(add.last);
  await tester.pump(const Duration(milliseconds: 800));
  // Form opened; submit empty to trigger validation, never save.
  final save = find.widgetWithText(ElevatedButton, 'Add Vehicle');
  expect(save, findsWidgets);
  await tester.ensureVisible(save.last);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(save.last);
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.text('Plate number is required'), findsOneWidget);
  await _pop(tester); // form
  expect(find.byType(RiderVehicleManagementScreen), findsOneWidget);
  await _pop(tester); // list
}

Future<void> _language(WidgetTester tester) async {
  await _openMore(tester);
  final container = ProviderScope.containerOf(
    tester.element(find.byType(RiderMainScreen)),
    listen: false,
  );
  try {
    final langRow = find.text('Language');
    await _scrollFind(tester, RiderMoreView, langRow);
    await tester.tap(langRow.last);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Filipino').last);
    await tester.pump(const Duration(milliseconds: 600));
    expect(container.read(appLanguageProvider), AppLanguage.filipino);
    await tester.tap(find.text('English').last);
    await tester.pump(const Duration(milliseconds: 600));
    expect(container.read(appLanguageProvider), AppLanguage.english);
    await _pop(tester);
  } finally {
    await container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.english);
    await tester.pump(const Duration(milliseconds: 400));
  }
  expect(container.read(appLanguageProvider), AppLanguage.english);
}

Future<void> _darkMode(WidgetTester tester) async {
  await _openMore(tester);
  final sw = find.byType(Switch);
  await _scrollFind(tester, RiderMoreView, sw);
  bool value() => tester.widget<Switch>(sw.first).value;
  final initial = value();
  await tester.tap(sw.first);
  await tester.pump(const Duration(milliseconds: 600));
  expect(value(), !initial);
  await tester.tap(sw.first);
  await tester.pump(const Duration(milliseconds: 600));
  expect(value(), initial);
}

Future<void> _faqs(WidgetTester tester) async {
  await _pushNamed(tester, MainRoutes.riderFaqs, find.byType(RiderFaqsScreen));
  await tester.pump(const Duration(seconds: 3));
  final tiles = find.byType(ExpansionTile);
  if (tiles.evaluate().isNotEmpty) {
    await tester.tap(tiles.first);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<ExpansionTile>(tiles.first).initiallyExpanded,
        isNotNull);
    await tester.tap(tiles.first);
    await tester.pump(const Duration(milliseconds: 500));
  } else {
    // ignore: avoid_print
    print('no FAQ articles present');
  }
  await _pop(tester);
}

Future<void> _notifSettings(WidgetTester tester) async {
  await _pushNamed(
    tester,
    MainRoutes.riderNotificationSettings,
    find.byType(RiderNotificationSettingsScreen),
  );
  await _pumpUntil(tester, find.byType(SwitchListTile));
  final switches = find.byType(SwitchListTile);
  final n = switches.evaluate().length;
  expect(n, greaterThanOrEqualTo(4));
  final initial = [
    for (var i = 0; i < n; i++) tester.widget<SwitchListTile>(switches.at(i)).value,
  ];
  for (var i = 0; i < n; i++) {
    await tester.ensureVisible(switches.at(i));
    await tester.tap(switches.at(i));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.widget<SwitchListTile>(switches.at(i)).value, !initial[i]);
  }
  for (var i = 0; i < n; i++) {
    await tester.tap(switches.at(i));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.widget<SwitchListTile>(switches.at(i)).value, initial[i]);
  }
  await _pop(tester); // never saved
}

Future<void> _schedule(WidgetTester tester) async {
  await _pushNamed(
    tester,
    MainRoutes.riderSchedule,
    find.byType(RiderScheduleScreen),
  );
  await tester.pump(const Duration(seconds: 2));
  // Open the add-schedule sheet and dismiss it without saving.
  final addBtn = find.descendant(
    of: find.byType(RiderScheduleScreen),
    matching: find.byIcon(Icons.add_rounded),
  );
  final addAlt = find.descendant(
    of: find.byType(RiderScheduleScreen),
    matching: find.byIcon(Icons.add),
  );
  final target = addBtn.evaluate().isNotEmpty ? addBtn : addAlt;
  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target.first);
    await tester.tap(target.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 800));
    // Dismiss bottom sheet by tapping the barrier.
    await tester.tapAt(const Offset(20, 60));
    await tester.pump(const Duration(milliseconds: 600));
  } else {
    // ignore: avoid_print
    print('schedule add control not found');
  }
  expect(find.byType(RiderScheduleScreen), findsOneWidget);
  await _pop(tester);
}

Future<void> _wallet(WidgetTester tester) async {
  await _openMoreRow(tester, 'Open wallet', find.text('Top up'));
  // Top-up validation only.
  await tester.tap(find.text('Top up').last);
  await tester.pump(const Duration(milliseconds: 600));
  final amount = find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(TextFormField),
  );
  expect(amount, findsOneWidget);
  final dialogBtns = find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(FilledButton),
  );
  // Empty / too small validations without ever submitting a valid amount.
  final form = tester.state<FormState>(
    find.descendant(of: find.byType(Dialog), matching: find.byType(Form)),
  );
  expect(form.validate(), isFalse);
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('Please enter an amount'), findsOneWidget);
  await tester.enterText(amount, '5');
  expect(form.validate(), isFalse);
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('Minimum amount is PHP 10.00'), findsOneWidget);
  expect(dialogBtns, findsWidgets);
  Navigator.of(tester.element(find.byType(Dialog)), rootNavigator: true).pop();
  await tester.pump(const Duration(milliseconds: 500));

  // History screen.
  await _tapText(tester, 'History');
  await _pumpUntil(tester, find.byType(RiderWalletHistoryScreen));
  await tester.pump(const Duration(seconds: 2));
  await _pop(tester);

  // Payout screen (view only).
  await _pushNamed(
    tester,
    MainRoutes.riderPayout,
    find.byType(RiderPayoutScreen),
  );
  await tester.pump(const Duration(seconds: 2));
  await _pop(tester);

  // Leave wallet screen.
  await _pop(tester);
  expect(find.byType(RiderMoreView).hitTestable(), findsOneWidget);
}

Future<void> _csChat(WidgetTester tester) async {
  await _pushNamed(
    tester,
    MainRoutes.riderCustomerServiceChat,
    find.byType(RiderCustomerServiceChatScreen),
  );
  await tester.pump(const Duration(seconds: 2));
  final field = find.descendant(
    of: find.byType(RiderCustomerServiceChatScreen),
    matching: find.byType(TextField),
  );
  expect(field, findsOneWidget);
  await tester.enterText(field, 'QA draft message, not sent');
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('QA draft message, not sent'), findsOneWidget);
  await tester.enterText(field, '');
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 300));
  await _pop(tester);
}

Future<void> _signIn(
  WidgetTester tester, {
  required String accountType,
  required String email,
  required String password,
  required List<Finder> landingScreens,
}) async {
  await RememberMeService.init();
  await RememberMeService.clearSession();
  await SecureStorageService.clearAll();
  await app.main();
  await _pumpUntil(tester, find.text('Login'));
  await tester.tap(find.text('Login').first);
  await tester.pumpAndSettle();

  final accountButton = find.text(
    accountType == 'merchant' ? 'Merchant' : 'Rider',
  );
  await _pumpUntil(tester, accountButton);
  await tester.tap(accountButton.first);
  await tester.pumpAndSettle();

  final form = find.byKey(ValueKey('${accountType}_login_form'));
  await _pumpUntil(tester, form);
  final fields = find.descendant(
    of: form,
    matching: find.byType(TextFormField),
  );
  expect(fields, findsNWidgets(2));
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();

  final submit = find.text('Log In');
  await tester.ensureVisible(submit);
  await tester.pumpAndSettle();
  await tester.tap(submit);
  await _pumpUntilAny(tester, landingScreens, maxPumps: 200);
  expect(
    landingScreens.any((screen) => screen.evaluate().isNotEmpty),
    isTrue,
    reason:
        'The $accountType login did not reach the home or fee-status screen.',
  );
}

Future<void> _pumpUntilAny(
  WidgetTester tester,
  List<Finder> finders, {
  int maxPumps = 120,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finders.any((finder) => finder.evaluate().isNotEmpty)) return;
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Timed out waiting for one of the expected screens.');
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 120,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Timed out waiting for the expected screen.');
}

Finder _textFieldWithHint(bool Function(String) matchesHint) =>
    find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText != null &&
          matchesHint(widget.decoration!.hintText!),
    );

Future<void> _pumpUntilGone(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 120; i++) {
    if (finder.evaluate().isEmpty) return;
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Timed out for the expected screen to close.');
}
