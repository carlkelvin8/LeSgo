// Deep UI sweep for the seeded rider + merchant: opens every reachable
// secondary screen and fails on any framework exception (overflow, null, etc).
// Run: scripts/e2e-emulator.sh full
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lezgo_rider/core/services/remember_me_service.dart';
import 'package:lezgo_rider/core/services/secure_storage_service.dart';
import 'package:lezgo_rider/main.dart' as app;
import 'package:lezgo_rider/core/constants/routers/main/main_routes.dart';
import 'package:lezgo_rider/core/services/notification_navigation_service.dart';
import 'package:lezgo_rider/presentation/widgets/main/merchantside/merchant_bottom_nav_bar.dart';
import 'package:lezgo_rider/presentation/widgets/main/riderside/rider_bottom_nav_bar.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_main_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_main_screen.dart';

const _m = String.fromEnvironment('LES_GO_TEST_MERCHANT_EMAIL');
const _mp = String.fromEnvironment('LES_GO_TEST_MERCHANT_PASSWORD');
const _r = String.fromEnvironment('LES_GO_TEST_RIDER_EMAIL');
const _rp = String.fromEnvironment('LES_GO_TEST_RIDER_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rider: every More/Profile screen opens cleanly', (t) async {
    await _signIn(t, 'rider', _r, _rp, find.byType(RiderMainScreen));
    await _tab(t, 'More');
    for (final label in [
      'My Earnings',
      'Earnings Insights',
      'Missions',
      'My Rating',
      'My Vehicles',
      'Scheduled Availability',
      'Package Tier',
    ]) {
      await _open(t, label);
    }
    await _tab(t, 'Inbox');
    await _tab(t, 'History');
    await _tab(t, 'Profile');
    for (final label in [
      'Edit Profile',
      'Document verification',
      'Change Password',
      'Security & 2FA',
      'Notification Settings',
    ]) {
      await _open(t, label); // never taps deactivate/delete account
    }
    await _scrollTextTour(t);
    // Every remaining rider screen, pushed by named route (never the
    // delete/deactivate-account screens, which are destructive).
    for (final r in [
      MainRoutes.riderEarnings,
      MainRoutes.riderEarningsInsights,
      MainRoutes.riderSafety,
      MainRoutes.riderSchedule,
      MainRoutes.riderScheduledPayout,
      MainRoutes.riderRating,
      MainRoutes.riderVehicleManagement,
      MainRoutes.riderQuickStats,
      MainRoutes.riderPayout,
      MainRoutes.riderTripAnalytics,
      MainRoutes.riderPerformance,
      MainRoutes.riderChatList,
      MainRoutes.riderFaqs,
      MainRoutes.riderOffers,
      MainRoutes.riderLoyalty,
      MainRoutes.riderReferral,
      MainRoutes.riderSecurity,
      MainRoutes.riderNotifications,
      MainRoutes.riderNotificationSettings,
      MainRoutes.riderCustomerServiceChat,
      MainRoutes.riderDocuments,
      MainRoutes.riderChangePassword,
    ]) {
      await _pushRoute(t, r);
    }
    // Wallet sub-screens + a history/booking detail if the seed has any.
    await t.pump(const Duration(seconds: 1));
    await _tab(t, 'More');
    if (find.text('Open wallet').evaluate().isEmpty) await _tab(t, 'More');
    await _open(t, 'Open wallet');
    await _tab(t, 'History');
    await _openFirstCard(t);
  });

  testWidgets('merchant: secondary screens open cleanly', (t) async {
    await _signIn(t, 'merchant', _m, _mp, find.byType(MerchantMainScreen));
    for (final tab in ['Orders', 'Profile', 'Menu', 'LeSpay', 'Book']) {
      await _tab(t, tab);
    }
    await _tab(t, 'Profile');
    for (final r in [
      MainRoutes.merchantMissions,
      MainRoutes.merchantReviews,
      MainRoutes.merchantAnalytics,
      MainRoutes.merchantSalesReport,
      MainRoutes.merchantStaff,
      MainRoutes.merchantBranches,
      MainRoutes.merchantPrinterSettings,
      MainRoutes.merchantFaqs,
      MainRoutes.merchantOffers,
      MainRoutes.merchantLoyalty,
      MainRoutes.merchantReferral,
      MainRoutes.merchantSecurity,
      MainRoutes.merchantSupportTickets,
      MainRoutes.merchantDocuments,
    ]) {
      await _pushRoute(t, r);
    }
    await _tab(t, 'Orders');
    await _openFirstCard(t); // order detail, if the test store has orders
  });
}

/// Taps a tab label in whichever bottom nav is showing.
Future<void> _tab(WidgetTester t, String label) async {
  final nav = find.byType(RiderBottomNavBar).evaluate().isNotEmpty
      ? find.byType(RiderBottomNavBar)
      : find.byType(MerchantBottomNavBar);
  final f = find.descendant(of: nav, matching: find.text(label));
  expect(f, findsWidgets, reason: 'tab "$label" not found');
  await t.tap(f.last, warnIfMissed: false);
  await t.pump(const Duration(milliseconds: 900));
  _noErrors(t, 'tab $label');
}

/// Opens a row by its text, waits, asserts no exception, then navigates back.
Future<void> _open(WidgetTester t, String label) async {
  final f = find.text(label);
  await _until(t, f, pumps: 40);
  expect(f, findsWidgets, reason: 'row "$label" not found');
  await t.ensureVisible(f.last);
  await t.pump(const Duration(milliseconds: 300));
  await t.tap(f.last, warnIfMissed: false);
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 250));
  }
  _noErrors(t, 'screen "$label"');
  await _backToMain(t);
  _noErrors(t, 'back from "$label"');
}

/// Pushes a named route on the app navigator, waits, asserts, pops it.
Future<void> _pushRoute(WidgetTester t, String route) async {
  final nav = NotificationNavigationService.navigatorKey.currentState!;
  nav.pushNamed(route);
  for (var i = 0; i < 16; i++) {
    await t.pump(const Duration(milliseconds: 250));
  }
  _noErrors(t, 'route $route');
  nav.pop();
  await t.pump(const Duration(milliseconds: 600));
  _noErrors(t, 'back from $route');
}

/// Taps the first InkWell/ListTile card in the current tab (detail screens).
Future<void> _openFirstCard(WidgetTester t) async {
  final card = find.byType(InkWell).hitTestable();
  if (card.evaluate().length < 3) return;
  await t.tap(card.at(2), warnIfMissed: false);
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 250));
  }
  _noErrors(t, 'first card detail');
  await _backToMain(t);
}

/// Pops routes until a main screen (rider or merchant) is the top route.
Future<void> _backToMain(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    final mainShown = find.byType(RiderMainScreen).hitTestable().evaluate().isNotEmpty ||
        find.byType(MerchantMainScreen).hitTestable().evaluate().isNotEmpty;
    if (mainShown) return;
    final nav = Navigator.of(t.element(find.byType(Scaffold).last));
    if (!nav.canPop()) return;
    nav.pop();
    await t.pump(const Duration(milliseconds: 600));
  }
}

/// Scrolls the profile tab top→bottom so lazily built sections get laid out.
Future<void> _scrollTextTour(WidgetTester t) async {
  final scrollable = find.byType(Scrollable).hitTestable();
  if (scrollable.evaluate().isEmpty) return;
  for (var i = 0; i < 6; i++) {
    await t.drag(scrollable.first, const Offset(0, -400));
    await t.pump(const Duration(milliseconds: 300));
    _noErrors(t, 'profile scroll $i');
  }
}

void _noErrors(WidgetTester t, String where) {
  final e = t.takeException();
  if (e != null) fail('Exception at $where: $e');
}

Future<void> _signIn(WidgetTester t, String type, String email, String pw,
    Finder landing) async {
  await RememberMeService.init();
  await RememberMeService.clearSession();
  await SecureStorageService.clearAll();
  await app.main();
  await _until(t, find.text('Login'));
  await t.tap(find.text('Login').first);
  await t.pumpAndSettle();
  final btn = find.text(type == 'merchant' ? 'Merchant' : 'Rider');
  await _until(t, btn);
  await t.tap(btn.first);
  await t.pumpAndSettle();
  final form = find.byKey(ValueKey('${type}_login_form'));
  await _until(t, form);
  final fields =
      find.descendant(of: form, matching: find.byType(TextFormField));
  await t.enterText(fields.at(0), email);
  await t.enterText(fields.at(1), pw);
  FocusManager.instance.primaryFocus?.unfocus();
  await t.pumpAndSettle();
  await t.tap(find.text('Log In'));
  await _until(t, landing, pumps: 200);
  await t.pump(const Duration(seconds: 2));
}

Future<void> _until(WidgetTester t, Finder f, {int pumps = 120}) async {
  for (var i = 0; i < pumps; i++) {
    if (f.evaluate().isNotEmpty) return;
    await t.pump(const Duration(milliseconds: 250));
  }
  fail('Timed out waiting for $f');
}
