import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lezgo_rider/core/services/api_service.dart';
import 'package:lezgo_rider/core/services/remember_me_service.dart';
import 'package:lezgo_rider/core/services/secure_storage_service.dart';
import 'package:lezgo_rider/data/data_source/dto/merchant/partner_dto.dart';
import 'package:lezgo_rider/data/data_source/merchant_remote_datasource.dart';
import 'package:lezgo_rider/main.dart' as app;
import 'package:lezgo_rider/presentation/provider/auth/rider_auth_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_branch_form_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_branches_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_edit_information_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_main_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_staff_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/printer_settings_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_book_view.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_orders_view.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_profile_view.dart';
import 'package:lezgo_rider/presentation/screens/registration_fee_screen.dart';
import 'package:lezgo_rider/presentation/widgets/main/merchantside/merchant_bottom_nav_bar.dart';
import 'package:lezgo_rider/presentation/widgets/register/merchant/info/merchant_location_pin_picker.dart';

const _merchantEmail = String.fromEnvironment('LES_GO_TEST_MERCHANT_EMAIL');
const _merchantPassword = String.fromEnvironment(
  'LES_GO_TEST_MERCHANT_PASSWORD',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('merchant data-changing flows with cleanup', (tester) async {
    expect(_merchantEmail, isNotEmpty);
    expect(_merchantPassword, isNotEmpty);

    await _signIn(
      tester,
      accountType: 'merchant',
      email: _merchantEmail,
      password: _merchantPassword,
      landingScreens: [
        find.byType(MerchantMainScreen),
        find.byType(RegistrationFeeScreen),
      ],
    );
    expect(
      find.byType(MerchantMainScreen),
      findsOneWidget,
      reason: 'Merchant landed on the registration fee screen.',
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MerchantMainScreen)),
      listen: false,
    );
    final partnerId = container.read(riderAuthProvider).user?.partnerId;
    expect(partnerId, isNotNull, reason: 'Merchant session has no partner ID.');
    final remote = MerchantRemoteDataSource();

    // Snapshot the original profile so every flow below can be undone.
    final original = await remote.getPartnerProfile(partnerId!);
    final steps = <String>[];

    try {
      await _tapMerchantTab(tester, 'Book');
      await _exerciseBookView(tester, remote, partnerId);
      steps.add('book view');

      await _tapMerchantTab(tester, 'Orders');
      await _exerciseOrderSearchAndFilters(tester);
      steps.add('order search/filter');

      await _tapMerchantTab(tester, 'Profile');
      await _exerciseBranchLifecycle(tester, partnerId);
      steps.add('branch add/edit/delete');

      await _exerciseEditInformation(tester, remote, partnerId, original);
      steps.add('edit information');

      await _exerciseOperatingHoursSave(tester, remote, partnerId, original);
      steps.add('operating hours');

      await _exerciseStaffValidation(tester);
      steps.add('staff invite validation');

      await _exercisePrinterSettings(tester);
      steps.add('printer settings');
    } finally {
      // Restore profile fields no matter what happened above.
      try {
        await remote.updatePartnerProfile(
          partnerId,
          UpdatePartnerRequest(
            name: original.name,
            supportPhone: original.supportPhone,
            supportEmail: original.supportEmail,
            estimatedDeliveryMinutes: original.estimatedDeliveryMinutes,
            openingHours: original.openingHours ?? <String, dynamic>{},
          ),
        );
      } catch (e) {
        // ignore: avoid_print
        print('CLEANUP profile restore failed: $e');
      }
      await _deleteQaBranches(partnerId);
      // ignore: avoid_print
      print('COMPLETED STEPS: $steps');
    }
  });
}

Future<void> _deleteQaBranches(int partnerId) async {
  try {
    final response = await ApiService.dio.get('/v1/partners/$partnerId/branches');
    final data = response.data;
    final raw = data is Map ? data['data'] : data;
    for (final b in (raw is List ? raw : const []).whereType<Map>()) {
      final name = '${b['name']}';
      if (name.startsWith('QA Branch') && b['is_primary'] != true) {
        await ApiService.dio.delete('/v1/branches/${b['id']}');
      }
    }
  } catch (e) {
    // ignore: avoid_print
    print('CLEANUP branches failed: $e');
  }
}

Future<void> _exerciseBookView(
  WidgetTester tester,
  MerchantRemoteDataSource remote,
  int partnerId,
) async {
  await _pumpUntil(tester, find.byType(MerchantBookView));
  expect(find.text('Browse your menu categories'), findsOneWidget);
  final menu = await remote.getMerchantMenu(partnerId);
  await tester.pump(const Duration(seconds: 2));
  for (final category in menu.categories.take(4)) {
    final chip = find.text(category.name);
    if (chip.evaluate().isEmpty) continue;
    await tester.tap(chip.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    // Tapping again deselects (toggle).
    await tester.tap(chip.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
  }
  expect(find.byType(MerchantBookView), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _exerciseOrderSearchAndFilters(WidgetTester tester) async {
  await _pumpUntil(tester, find.byType(MerchantOrdersView));
  for (final label in [
    'Pending',
    'For Pick Up',
    'Ready',
    'For Delivery',
    'Completed',
    'Cancelled',
    'All',
  ]) {
    final chip = find.descendant(
      of: find.byType(MerchantOrdersView),
      matching: find.text(label),
    );
    if (chip.evaluate().isEmpty) continue;
    await Scrollable.ensureVisible(tester.element(chip.first), alignment: 0.5);
    await tester.tap(chip.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 350));
  }
  final search = find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Search order, customer or item',
  );
  expect(search, findsOneWidget);
  await tester.ensureVisible(search);
  await tester.enterText(search, 'QA no-match order');
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 300));
  await _pumpUntil(tester, find.text('No matching orders'));
  await tester.ensureVisible(find.text('Clear search'));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text('Clear search'));
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(find.text('No matching orders'), findsNothing);
}

Future<void> _exerciseBranchLifecycle(WidgetTester tester, int partnerId) async {
  final suffix = DateTime.now().millisecondsSinceEpoch.toString();
  final name = 'QA Branch $suffix';
  final renamed = 'QA Branch Edited $suffix';

  try {
    await _openMerchantProfileRoute(
      tester,
      'Branches & Pickup Points',
      MerchantBranchesScreen,
    );
    await _pumpUntil(tester, find.text('Add Branch'));
    await tester.tap(find.text('Add Branch'));
    await _pumpUntil(tester, find.byType(MerchantBranchFormScreen));

    Finder field(String label) => find.widgetWithText(TextFormField, label);
    await tester.enterText(field('Branch name'), name);
    await tester.enterText(field('Street address'), '123 QA Street');
    await tester.enterText(field('City'), 'Cagayan de Oro');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    // Drop the map pin the same way a tap on the map would.
    tester
        .widget<MerchantLocationPinPicker>(find.byType(MerchantLocationPinPicker))
        .onLocationChanged(8.4542, 124.6319);
    await tester.pump(const Duration(milliseconds: 300));
    final add = find.text('Add branch');
    await tester.ensureVisible(add);
    await tester.tap(add);
    await _pumpUntilGone(tester, find.byType(MerchantBranchFormScreen));
    await _pumpUntil(tester, find.text(name));

    Finder menuFor(String branchName) => find.descendant(
      of: find.ancestor(of: find.text(branchName), matching: find.byType(Card)),
      matching: find.byType(PopupMenuButton<String>),
    );

    // Edit.
    await tester.ensureVisible(menuFor(name).first);
    await tester.tap(menuFor(name).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit').last);
    await _pumpUntil(tester, find.text('Edit Branch'));
    await tester.enterText(field('Branch name'), renamed);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    final save = find.text('Save changes');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await _pumpUntilGone(tester, find.byType(MerchantBranchFormScreen));
    await _pumpUntil(tester, find.text(renamed));
    expect(find.text(name), findsNothing);

    // Delete.
    await tester.ensureVisible(menuFor(renamed).first);
    await tester.tap(menuFor(renamed).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Delete branch'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await _pumpUntilGone(tester, find.text(renamed));
  } finally {
    await _deleteQaBranches(partnerId);
    // Make sure we are back on the profile tab for the next flow.
    if (find.byType(MerchantBranchFormScreen).evaluate().isNotEmpty) {
      await _tapScreenBack(tester, find.byType(MerchantBranchFormScreen));
      await tester.pump(const Duration(milliseconds: 400));
    }
    if (find.byType(MerchantBranchesScreen).evaluate().isNotEmpty) {
      await _tapScreenBack(tester, find.byType(MerchantBranchesScreen));
      await tester.pump(const Duration(milliseconds: 500));
    }
  }
  expect(find.byType(MerchantProfileView), findsOneWidget);
}

Future<void> _exerciseEditInformation(
  WidgetTester tester,
  MerchantRemoteDataSource remote,
  int partnerId,
  PartnerDto original,
) async {
  await _openMerchantProfileRoute(
    tester,
    'Edit Information',
    MerchantEditInformationScreen,
  );
  final prepLabel = find.text('ESTIMATED PREPARATION TIME');
  await _pumpUntil(tester, prepLabel);
  // Wait for the profile to hydrate the form.
  await tester.pump(const Duration(seconds: 2));
  final originalPrep = original.estimatedDeliveryMinutes ?? 30;
  final newPrep = originalPrep >= 60 ? originalPrep - 5 : originalPrep + 5;
  final prepField = find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.suffixText == 'minutes',
  );
  await tester.ensureVisible(prepField);
  await tester.enterText(prepField, '$newPrep');
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text('Save').first);
  await _pumpUntil(tester, find.text('Information updated successfully'));
  await _pumpUntilGone(tester, find.byType(MerchantEditInformationScreen));
  final updated = await remote.getPartnerProfile(partnerId);
  expect(updated.estimatedDeliveryMinutes, newPrep);
  expect(updated.name, original.name, reason: 'Name changed unexpectedly.');
  // Restore.
  await remote.updatePartnerProfile(
    partnerId,
    UpdatePartnerRequest(estimatedDeliveryMinutes: originalPrep),
  );
  final restored = await remote.getPartnerProfile(partnerId);
  expect(restored.estimatedDeliveryMinutes, originalPrep);
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(MerchantProfileView), findsOneWidget);
}

Future<void> _exerciseOperatingHoursSave(
  WidgetTester tester,
  MerchantRemoteDataSource remote,
  int partnerId,
  PartnerDto original,
) async {
  await _openMerchantProfileRoute(
    tester,
    'Edit Information',
    MerchantEditInformationScreen,
  );
  final hoursTile = find.text('OPERATING HOURS');
  await _pumpUntil(tester, hoursTile);
  await tester.pump(const Duration(seconds: 2));
  await tester.ensureVisible(hoursTile.first);
  await tester.tap(hoursTile.first);
  await _pumpUntil(tester, find.text('Monday'));

  // Monday is the first row; its toggle pill reads 'Close' while open.
  final closePill = find.text('Close').first;
  await tester.ensureVisible(closePill);
  await tester.tap(closePill);
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('Closed'), findsWidgets,
      reason: 'Tapping Close on Monday did not mark it closed.');
  await tester.tap(find.text('Save').first);
  await _pumpUntil(tester, find.text('Operating hours saved'));
  await tester.pump(const Duration(milliseconds: 600));
  expect(find.byType(MerchantEditInformationScreen), findsOneWidget);

  await tester.tap(find.text('Save').first);
  await _pumpUntilGone(tester, find.byType(MerchantEditInformationScreen));
  final updated = await remote.getPartnerProfile(partnerId);
  final monday = updated.openingHours?['monday'];
  expect(monday, isNotNull, reason: 'Monday hours were not persisted.');
  final originalMonday = original.openingHours?['monday'];
  expect(
    '$monday' == '$originalMonday',
    isFalse,
    reason: 'Saved hours are identical to the original; toggle did not apply.',
  );
  await remote.updatePartnerProfile(
    partnerId,
    UpdatePartnerRequest(
      openingHours: original.openingHours ?? <String, dynamic>{},
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(MerchantProfileView), findsOneWidget);
}

Future<void> _exerciseStaffValidation(WidgetTester tester) async {
  await _openMerchantProfileRoute(tester, 'Staff Accounts', MerchantStaffScreen);
  final fab = find.byType(FloatingActionButton).hitTestable();
  await _pumpUntil(tester, fab);
  await tester.pump(const Duration(seconds: 1));
  await tester.tap(fab.last);
  await _pumpUntil(tester, find.text('Temporary Password'));
  // Empty submit -> validation, nothing created.
  // Earlier steps leave queued snackbars that would delay this one.
  ScaffoldMessenger.of(tester.element(find.byType(MerchantStaffScreen)))
      .clearSnackBars();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text('Invite').last);
  await _pumpUntil(tester, find.text('All fields are required'));
  expect(find.text('All fields are required'), findsOneWidget);
  // The app closes the dialog on Invite and validates on the screen, so the
  // dialog is gone and nothing was created.
  expect(find.text('Temporary Password'), findsNothing);
  expect(find.byType(MerchantStaffScreen), findsOneWidget);
  await _tapScreenBack(tester, find.byType(MerchantStaffScreen));
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(MerchantProfileView), findsOneWidget);
}

Future<void> _exercisePrinterSettings(WidgetTester tester) async {
  await _openMerchantProfileRoute(
    tester,
    'Printer Settings',
    PrinterSettingsScreen,
  );
  expect(find.text('Printer Settings'), findsWidgets);
  await _tapScreenBack(tester, find.byType(PrinterSettingsScreen));
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(MerchantProfileView), findsOneWidget);
}

Future<void> _tapMerchantTab(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(MerchantBottomNavBar),
    matching: find.text(label),
  );
  expect(tab, findsOneWidget, reason: 'Missing merchant tab: $label');
  await tester.tap(tab, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _tapScreenBack(WidgetTester tester, Finder screen) async {
  final adaptiveBack = find.descendant(
    of: screen,
    matching: find.byType(BackButton),
  );
  if (adaptiveBack.evaluate().isNotEmpty) {
    await tester.tap(adaptiveBack.last);
    return;
  }
  final materialArrow = find.descendant(
    of: screen,
    matching: find.byIcon(Icons.arrow_back),
  );
  if (materialArrow.evaluate().isNotEmpty) {
    await tester.tap(materialArrow.last);
    return;
  }
  final labeledBack = find.descendant(
    of: screen,
    matching: find.byTooltip('Back'),
  );
  expect(
    labeledBack,
    findsWidgets,
    reason: 'The current screen has no back control.',
  );
  await tester.tap(labeledBack.last);
}

Future<void> _openMerchantProfileRoute(
  WidgetTester tester,
  String label,
  Type screenType,
) async {
  final action = find.text(label).last;
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pump(const Duration(milliseconds: 500));
  expect(
    find.byType(screenType),
    findsOneWidget,
    reason: 'The $label merchant action did not open its screen.',
  );
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

Future<void> _pumpUntilGone(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 120; i++) {
    if (finder.evaluate().isEmpty) return;
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Timed out for the expected screen to close.');
}
