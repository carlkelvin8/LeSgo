import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lezgo_rider/core/constants/api_constants.dart';
import 'package:lezgo_rider/core/services/remember_me_service.dart';
import 'package:lezgo_rider/core/services/secure_storage_service.dart';
import 'package:lezgo_rider/data/data_source/merchant_remote_datasource.dart';
import 'package:lezgo_rider/main.dart' as app;
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_main_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_menu_add_category_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_menu_add_item_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_menu_edit_item_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_analytics_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_branches_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_branch_form_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_edit_information_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_reviews_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_sales_report_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_staff_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_withdrawal_history_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/printer_settings_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_book_view.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_lespay_view.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_menu_view.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_orders_view.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_profile_view.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_main_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_edit_profile_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_bookings_view.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_history_view.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_inbox_view.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_mission_view.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_more_view.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_profile_view.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_wallet_view.dart';
import 'package:lezgo_rider/presentation/widgets/main/riderside/rider_bottom_nav_bar.dart';
import 'package:lezgo_rider/presentation/screens/registration_fee_screen.dart';
import 'package:lezgo_rider/presentation/widgets/main/merchantside/merchant_bottom_nav_bar.dart';
import 'package:lezgo_rider/presentation/provider/auth/rider_auth_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_menu_item_form_provider.dart';

const _merchantEmail = String.fromEnvironment('LES_GO_TEST_MERCHANT_EMAIL');
const _merchantPassword = String.fromEnvironment(
  'LES_GO_TEST_MERCHANT_PASSWORD',
);
const _riderEmail = String.fromEnvironment('LES_GO_TEST_RIDER_EMAIL');
const _riderPassword = String.fromEnvironment('LES_GO_TEST_RIDER_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('merchant seeded account can log in', (tester) async {
    expect(
      ApiConstants.baseUrl,
      'https://lesgo-api-feature-auth-fhlrsy.laravel.cloud/api',
    );
    expect(
      _merchantEmail,
      isNotEmpty,
      reason: 'Pass the seeded merchant account through --dart-define.',
    );
    expect(
      _merchantPassword,
      isNotEmpty,
      reason: 'Pass the seeded merchant password through --dart-define.',
    );

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

    if (find.byType(MerchantMainScreen).evaluate().isNotEmpty) {
      await _verifyMerchantPrimaryTabs(tester);
    }
  });

  testWidgets('rider seeded account can log in', (tester) async {
    expect(
      ApiConstants.baseUrl,
      'https://lesgo-api-feature-auth-fhlrsy.laravel.cloud/api',
    );
    expect(
      _riderEmail,
      isNotEmpty,
      reason: 'Pass the seeded rider account through --dart-define.',
    );
    expect(
      _riderPassword,
      isNotEmpty,
      reason: 'Pass the seeded rider password through --dart-define.',
    );

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
    if (find.byType(RiderMainScreen).evaluate().isNotEmpty) {
      await _verifyRiderPrimaryTabs(tester);
    }
  });
}

Future<void> _verifyRiderPrimaryTabs(WidgetTester tester) async {
  final tabs = [
    ('Bookings', RiderBookingsView),
    ('History', RiderHistoryView),
    ('Inbox', RiderInboxView),
    ('Profile', RiderProfileView),
    ('More', RiderMoreView),
  ];

  for (final (label, viewType) in tabs) {
    final tab = find.descendant(
      of: find.byType(RiderBottomNavBar),
      matching: find.text(label),
    );
    expect(tab, findsOneWidget, reason: 'Missing rider tab: $label');
    await tester.tap(tab);
    await tester.pump(const Duration(milliseconds: 450));
    expect(
      find.byType(viewType),
      findsOneWidget,
      reason: 'The rider $label tab did not open.',
    );
  }

  // Exercise map/list mode without toggling duty status or accepting a booking.
  await _tapRiderTab(tester, 'Bookings');
  final mapView = find.text('Map View');
  if (mapView.evaluate().isNotEmpty) {
    await tester.tap(mapView.first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('List View').first);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(RiderBookingsView), findsOneWidget);
  }

  await _tapRiderTab(tester, 'History');
  for (final filter in ['All', 'Completed', 'Processing', 'Cancelled']) {
    final chip = find.text(filter).last;
    if (chip.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(tester.element(chip), alignment: 0.5);
      await tester.tap(chip);
      await tester.pump(const Duration(milliseconds: 180));
    }
  }

  await _tapRiderTab(tester, 'Profile');
  final editProfile = find.text('Edit Profile');
  await _pumpUntil(tester, editProfile);
  await tester.ensureVisible(editProfile.last);
  await tester.tap(editProfile.last);
  await _pumpUntil(tester, find.byType(RiderEditProfileScreen));
  await tester.tap(find.byTooltip('Back').last);
  await tester.pump(const Duration(milliseconds: 400));
  final visibleProfile = find.byType(RiderProfileView).hitTestable();
  await _pumpUntil(tester, visibleProfile);
  expect(visibleProfile, findsOneWidget);

  await _tapRiderTab(tester, 'More');
  final openWallet = find.text('Open wallet');
  await _pumpUntil(tester, openWallet);
  await tester.tap(openWallet.first);
  await _pumpUntil(tester, find.byType(RiderWalletScreen));
  expect(find.byType(RiderWalletView), findsOneWidget);
  await tester.tap(find.byTooltip('Back').last);
  await tester.pump(const Duration(milliseconds: 350));
  expect(find.byType(RiderMoreView).hitTestable(), findsOneWidget);

  final missions = find.text('Missions').last;
  await tester.ensureVisible(missions);
  final missionRow = find
      .ancestor(of: missions, matching: find.byType(InkWell))
      .first;
  await tester.tap(missionRow);
  await _pumpUntil(tester, find.byType(RiderMissionView));
  expect(find.byType(RiderMissionView), findsOneWidget);
  Navigator.of(tester.element(find.byType(RiderMissionView))).pop();
  await tester.pump(const Duration(milliseconds: 350));
  expect(find.byType(RiderMoreView), findsOneWidget);
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
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _verifyMerchantPrimaryTabs(WidgetTester tester) async {
  final tabs = [
    ('Orders', MerchantOrdersView),
    ('Profile', MerchantProfileView),
    ('Menu', MerchantMenuView),
    ('LeSpay', MerchantLespayView),
    ('Book', MerchantBookView),
  ];

  for (final (label, viewType) in tabs) {
    final tab = find.descendant(
      of: find.byType(MerchantBottomNavBar),
      matching: find.text(label),
    );
    expect(tab, findsOneWidget, reason: 'Missing merchant tab: $label');
    await tester.tap(tab);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byType(viewType),
      findsOneWidget,
      reason: 'The $label tab did not display its merchant view.',
    );
    if (label == 'Menu') {
      await _exerciseMerchantMenuCrud(tester);
    } else if (label == 'Orders') {
      await _exerciseMerchantOrderSearch(tester);
    } else if (label == 'LeSpay') {
      await _exerciseMerchantWalletForms(tester);
    } else if (label == 'Book') {
      expect(find.text('Browse your menu categories'), findsOneWidget);
    }
  }

  await _tapMerchantTab(tester, 'Profile');
  final profileRoutes = [
    ('Business Overview', MerchantAnalyticsScreen),
    ('Sales Reports', MerchantSalesReportScreen),
    ('Customer Reviews', MerchantReviewsScreen),
    ('Edit Information', MerchantEditInformationScreen),
    ('Branches & Pickup Points', MerchantBranchesScreen),
    ('Staff Accounts', MerchantStaffScreen),
    ('Printer Settings', PrinterSettingsScreen),
  ];
  for (final (label, screenType) in profileRoutes) {
    await _openMerchantProfileRoute(tester, label, screenType);
    if (label == 'Business Overview') {
      await _exerciseAnalyticsPeriods(tester);
    } else if (label == 'Sales Reports') {
      await _exerciseSalesReportControls(tester);
    } else if (label == 'Customer Reviews') {
      await _exerciseReviewFilters(tester);
    } else if (label == 'Edit Information') {
      await _exerciseOperatingHours(tester);
    } else if (label == 'Branches & Pickup Points') {
      await _exerciseBranchFormValidation(tester);
    } else if (label == 'Staff Accounts') {
      await _exerciseStaffInviteValidation(tester);
    }
    await _tapScreenBack(tester, find.byType(screenType));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MerchantProfileView), findsOneWidget);
  }

  await _tapMerchantTab(tester, 'LeSpay');
  final withdrawalHistory = find.text('View Withdrawal History');
  await _pumpUntil(tester, withdrawalHistory);
  await tester.ensureVisible(withdrawalHistory);
  await tester.tap(withdrawalHistory);
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(MerchantWithdrawalHistoryScreen), findsOneWidget);

  Navigator.of(
    tester.element(find.byType(MerchantWithdrawalHistoryScreen)),
  ).pop();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _exerciseMerchantOrderSearch(WidgetTester tester) async {
  await _pumpUntil(tester, find.byType(MerchantOrdersView));
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
  expect(
    find.text('Try an order number, customer or menu item.'),
    findsOneWidget,
  );
  await tester.tap(find.text('Clear search'));
  await tester.pump(const Duration(milliseconds: 350));
  expect(find.text('No matching orders'), findsNothing);
  expect(find.byType(MerchantOrdersView), findsOneWidget);
}

Future<void> _exerciseAnalyticsPeriods(WidgetTester tester) async {
  await _pumpUntil(tester, find.text('Order Volume'));
  for (final label in ['Today', 'This Week', 'This Month', 'All Time']) {
    final chip = find.widgetWithText(FilterChip, label);
    if (chip.evaluate().isNotEmpty) {
      await tester.tap(chip);
      await tester.pump(const Duration(milliseconds: 350));
    }
  }
}

Future<void> _exerciseSalesReportControls(WidgetTester tester) async {
  await _pumpUntil(tester, find.text('Report Summary'));
  for (final label in ['Daily', 'Weekly', 'Monthly']) {
    final period = find.text(label);
    if (period.evaluate().isNotEmpty) {
      await tester.tap(period.first);
      await tester.pump(const Duration(milliseconds: 250));
    }
  }
  final dateRange = find.textContaining('202');
  if (dateRange.evaluate().isNotEmpty) {
    await tester.tap(dateRange.first);
    await tester.pump(const Duration(milliseconds: 300));
    if (find.text('OK').evaluate().isNotEmpty) {
      await tester.tap(find.text('OK'));
      await tester.pump(const Duration(milliseconds: 250));
    }
  }
  expect(find.text('Report Summary'), findsOneWidget);
}

Future<void> _exerciseReviewFilters(WidgetTester tester) async {
  await _pumpUntil(tester, find.text('All'));
  for (final label in ['5★', '4★', '3★', '2★', '1★', 'All']) {
    final filter = find.widgetWithText(FilterChip, label);
    if (filter.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(tester.element(filter), alignment: 1.0);
      await tester.tap(filter);
      await tester.pump(const Duration(milliseconds: 180));
    }
  }
}

Future<void> _exerciseOperatingHours(WidgetTester tester) async {
  final hoursTile = find.text('OPERATING HOURS');
  await _pumpUntil(tester, hoursTile);
  await tester.ensureVisible(hoursTile.first);
  await tester.tap(hoursTile.first);
  await _pumpUntil(tester, find.text('Monday'));
  expect(find.text('Operating Hours'), findsOneWidget);
  final hoursScaffold = find
      .ancestor(of: find.text('Monday'), matching: find.byType(Scaffold))
      .first;
  await _tapScreenBack(tester, hoursScaffold);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _exerciseBranchFormValidation(WidgetTester tester) async {
  final addBranch = find.text('Add Branch');
  await _pumpUntil(tester, addBranch);
  await tester.tap(addBranch);
  await _pumpUntil(tester, find.byType(MerchantBranchFormScreen));
  expect(find.text('Branch name'), findsOneWidget);
  expect(find.text('Street address'), findsOneWidget);
  final save = find.text('Add branch');
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pump(const Duration(milliseconds: 250));
  expect(find.text('Enter a branch name'), findsOneWidget);
  expect(find.text('Enter the street address'), findsOneWidget);
  await _tapScreenBack(tester, find.byType(MerchantBranchFormScreen));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _exerciseStaffInviteValidation(WidgetTester tester) async {
  final inviteStaff = find.byType(FloatingActionButton).hitTestable();
  await _pumpUntil(tester, inviteStaff);
  await tester.pump(const Duration(seconds: 1)); // let the FAB finish sliding in
  await tester.tap(inviteStaff.last);
  await _pumpUntil(tester, find.text('Temporary Password'));
  expect(find.text('Full Name'), findsOneWidget);
  expect(find.text('Email'), findsOneWidget);
  await tester.tap(find.text('Invite').last);
  await tester.pump(const Duration(milliseconds: 350));
  expect(find.text('All fields are required'), findsOneWidget);
  expect(find.byType(MerchantStaffScreen), findsOneWidget);
}

Future<void> _exerciseMerchantWalletForms(WidgetTester tester) async {
  await _pumpUntil(tester, find.text('LesPay'));
  final topUp = find.widgetWithText(InkWell, 'Top up');
  if (topUp.evaluate().isNotEmpty) {
    await tester.tap(topUp.first);
    await _pumpUntil(tester, find.text('Top up wallet'));
    expect(find.text('Amount to add'), findsOneWidget);
    await tester.tap(find.text('Continue to payment'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Minimum top-up is ₱50'), findsOneWidget);
    await tester.tapAt(const Offset(10, 80));
    await tester.pump(const Duration(milliseconds: 250));
  }

  final withdraw = find.widgetWithText(InkWell, 'Withdraw');
  if (withdraw.evaluate().isNotEmpty) {
    await tester.tap(withdraw.first);
    await _pumpUntil(tester, find.text('Withdraw Earnings'));
    await tester.tap(find.text('Submit Request'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Please enter a valid amount'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _exerciseMerchantMenuCrud(WidgetTester tester) async {
  final main = find.byType(MerchantMainScreen);
  expect(main, findsOneWidget);
  final container = ProviderScope.containerOf(
    tester.element(main),
    listen: false,
  );
  final partnerId = container.read(riderAuthProvider).user?.partnerId;
  expect(partnerId, isNotNull, reason: 'Merchant session has no partner ID.');

  final suffix = DateTime.now().millisecondsSinceEpoch.toString();
  final categoryName = 'QA Menu $suffix';
  final itemName = 'QA Item $suffix';
  final updatedItemName = 'QA Updated $suffix';
  final remote = MerchantRemoteDataSource();

  try {
    expect(find.byType(MerchantMenuView), findsOneWidget);
    final menuFab = find.byType(FloatingActionButton);
    await _pumpUntil(tester, menuFab);
    expect(menuFab, findsOneWidget);
    await tester.tap(menuFab);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Add Category'));
    await _pumpUntil(tester, find.byType(MerchantMenuAddCategoryScreen));
    await tester.enterText(find.byType(TextFormField).first, categoryName);
    await tester.tap(find.text('Create Category'));
    await _pumpUntilGone(tester, find.byType(MerchantMenuAddCategoryScreen));
    await _pumpUntil(tester, find.text(categoryName));

    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Add Menu'));
    await _pumpUntil(tester, find.byType(MerchantMenuAddItemScreen));
    final itemNameField = _textFieldWithHint(
      (hint) => hint.startsWith('Enter item name'),
    );
    final itemPriceField = _textFieldWithHint((hint) => hint == '0.00');
    expect(itemNameField, findsOneWidget);
    expect(itemPriceField, findsOneWidget);
    await tester.enterText(itemNameField, itemName);
    await tester.enterText(itemPriceField, '99.00');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 250));
    final categoryPicker = find.ancestor(
      of: find.text('Select a category'),
      matching: find.byType(DropdownButton<String>),
    );
    await Scrollable.ensureVisible(
      tester.element(categoryPicker),
      alignment: 0.5,
    );
    await tester.tap(categoryPicker);
    await tester.pumpAndSettle();
    await tester.tap(find.text(categoryName).last);
    await tester.pump(const Duration(milliseconds: 300));
    final formState = container.read(
      merchantMenuItemFormProvider(const MerchantMenuItemFormInput.add()),
    );
    expect(formState.category, categoryName);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('Add Item'));
    await tester.tap(find.text('Add Item'));
    await _pumpUntilGone(tester, find.byType(MerchantMenuAddItemScreen));
    await _pumpUntil(tester, find.text(itemName));

    final editAction = find
        .ancestor(
          of: find.text('Edit').last,
          matching: find.byType(GestureDetector),
        )
        .first;
    await tester.drag(find.byType(MerchantMenuView), const Offset(0, -360));
    await tester.pump(const Duration(milliseconds: 350));
    await Scrollable.ensureVisible(tester.element(editAction), alignment: 0.5);
    await tester.tap(editAction);
    await _pumpUntil(tester, find.byType(MerchantMenuEditItemScreen));
    await tester.enterText(
      _textFieldWithHint((hint) => hint.startsWith('Enter item name')),
      updatedItemName,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.ensureVisible(find.text('Save Item'));
    await tester.tap(find.text('Save Item'));
    await _pumpUntilGone(tester, find.byType(MerchantMenuEditItemScreen));
    await _pumpUntil(tester, find.text(updatedItemName));

    final deleteAction = find
        .ancestor(
          of: find.text('Del').last,
          matching: find.byType(GestureDetector),
        )
        .first;
    await tester.drag(find.byType(MerchantMenuView), const Offset(0, -240));
    await tester.pump(const Duration(milliseconds: 350));
    await Scrollable.ensureVisible(
      tester.element(deleteAction),
      alignment: 0.5,
    );
    await tester.tap(deleteAction);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Delete menu item'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await _pumpUntil(tester, find.text('Menu item deleted'));
    await _pumpUntilGone(tester, find.text(updatedItemName));
    ScaffoldMessenger.of(
      tester.element(find.byType(MerchantMenuView)),
    ).hideCurrentSnackBar();
    await tester.pump(const Duration(milliseconds: 300));
  } finally {
    final menu = await remote.getMerchantMenu(partnerId!);
    for (final category in menu.categories.where(
      (category) => category.name == categoryName,
    )) {
      for (final item in category.availableItems ?? const []) {
        await remote.deleteMenuItem(item.id);
      }
      await remote.deleteMenuCategory(category.id);
    }
  }
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
