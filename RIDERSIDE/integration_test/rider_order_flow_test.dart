// Rider order lifecycle, earnings/wallet math, rider<->customer chat and
// customer-service chat, driven through the real rider UI. Customer, merchant
// and admin act through the HTTP API of the LOCAL backend and every UI action
// is followed by an API assertion on the stored state.
//
// Run (local API on :8012, see the report for how it is started):
//   flutter test integration_test/rider_order_flow_test.dart \
//     -d A25FDC04-97C0-488D-84E0-1542AA1EFA59 \
//     --dart-define=API_BASE_URL=http://127.0.0.1:8012/api \
//     --dart-define=LES_GO_TEST_RIDER_EMAIL=testrider@lesgo.com \
//     --dart-define=LES_GO_TEST_RIDER_PASSWORD='TestRider123!'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lezgo_rider/core/constants/routers/main/main_routes.dart';
import 'package:lezgo_rider/core/services/notification_navigation_service.dart';
import 'package:lezgo_rider/presentation/screens/chat/rider_chat_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_booking_detail_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_customer_service_chat_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_history_view.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_main_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_bookings_view.dart';
import 'package:lezgo_rider/presentation/widgets/main/riderside/bookings/rider_swipe_accept_button.dart';

import 'support/rider_e2e_support.dart';

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rider order lifecycle (accept -> pickup -> proof -> complete)',
      (t) async {
    _tester = t;
    assertLocalApi();
    final picker = installFakeImagePicker();
    await api.cancelAllOpenOrders();

    // Start from OFF duty so the toggle is really exercised.
    var res = await api.call('PATCH', '/drivers/1',
        token: await api.admin, data: {'is_available': false});
    expect(res.statusCode, 200, reason: 'admin set off duty -> ${res.data}');
    expect((await api.riderProfile())['is_available'] == true ||
            (await api.riderProfile())['is_available'] == 1, isFalse);

    final walletStart = await api.walletBalance();
    final earningsStart = (await api.earnings('all'))['summary'];

    await signInRider(t);
    expect(find.byType(RiderMainScreen), findsOneWidget);
    await tapRiderTab(t, 'Bookings');
    expect(find.byType(RiderBookingsView), findsOneWidget);

    // ---- customer places an order, merchant marks it ready ---------------
    late int orderId;
    await step('customer order + merchant ready (off-duty rider sees nothing)',
        () async {
      orderId = await api.createOrder();
      var o = await api.order(orderId);
      expect(o['status'], 'pending');
      await api.merchantMarkReady(orderId);
      o = await api.order(orderId);
      expect(o['status'], 'ready_for_pickup');
      expect(o['ready_for_pickup_at'], isNotNull);
      expect(o['driver_id'], isNull);
      // Off duty: the server hides the open pool from the rider.
      final list = await api.call('GET', '/orders',
          token: await api.rider, query: {'per_page': 100});
      final ids = (api.body(list) as List).map((e) => e['id']).toList();
      expect(ids, isNot(contains(orderId)));
      expect(find.text('Swipe to get booking'), findsNothing);
      expect(find.text('Take a breather'), findsOneWidget);
    });

    // ---- duty toggle -----------------------------------------------------
    final dutySwitch = find.descendant(
        of: find.byType(RiderBookingsView), matching: find.byType(Switch));
    await step('go ON duty (attendance photo) -> API is_available=true',
        () async {
      await t.tap(dutySwitch.first);
      await pumpUntil(t, find.text('Open Camera'), what: 'attendance dialog');
      await t.tap(find.text('Open Camera'));
      await pollUntil(t, () async {
        final p = await api.riderProfile();
        return p['is_available'] == true || p['is_available'] == 1;
      }, what: 'is_available=true on server');
      expect(picker.pickCount, greaterThanOrEqualTo(1));
      // The switch is replaced by a spinner while the toggle is processing; it
      // must come back (regression: a missing GPS fix used to hang it forever).
      await pumpUntil(t, dutySwitch, pumps: 160, what: 'duty switch to return');
      noErrors(t, 'after go on duty');
      expect(switchValue(t, dutySwitch), isTrue);
    });

    await step('dispatched order appears in Bookings', () async {
      await pumpUntil(t, find.byType(RiderSwipeAcceptButton),
          pumps: 80, what: 'booking card with swipe-to-accept');
      expect(find.textContaining('LesGo Test Store'), findsWidgets);
    });

    final walletBeforeAccept = await api.walletBalance();

    await step('swipe to accept -> accepted, driver assigned, hold charged',
        () async {
      final thumb = find.descendant(
          of: find.byType(RiderSwipeAcceptButton),
          matching: find.byIcon(Icons.arrow_forward_rounded));
      await t.drag(thumb.first, const Offset(700, 0));
      await pollUntil(t, () async {
        final o = await api.order(orderId);
        return o['status'] == 'accepted';
      }, what: 'order accepted on server');
      final o = await api.order(orderId);
      expect(o['driver_id'], 1);
      expect(o['accepted_at'], isNotNull);
      // Customer-side view is what `api.order` returns (customer token).
      // Money: 20% of the estimated fare (min PHP 10) is held from the wallet.
      final fare = double.parse('${o['estimated_fare']}');
      // Hold = platform cut for the rider's tier (seeded rider: Basic, 30%), min PHP 10.
      final hold = (fare * 0.30) < 10 ? 10.0 : double.parse((fare * 0.30).toStringAsFixed(2));
      final after = await api.walletBalance();
      expect(after, closeTo(walletBeforeAccept - hold, 0.001));
      final tx = await api.walletTx();
      expect(tx.first['type'], 'debit');
      expect(double.parse('${tx.first['amount']}'), closeTo(hold, 0.001));
      expect('${tx.first['description']}', contains('#$orderId'));
      // 70/30 split for the Basic tier.
      expect(double.parse('${o['driver_share']}'), closeTo(fare * 0.7, 0.01));
      expect(double.parse('${o['platform_share']}'), closeTo(fare * 0.3, 0.01));
      await settle(t, 2000);
      noErrors(t, 'after accept');
    });

    await step('open the active order -> arrived -> picked up', () async {
      if (find.text('List View').evaluate().isNotEmpty) {
        await t.tap(find.text('List View').first);
        await settle(t, 800);
      }
      await pumpUntil(t, find.text('ACTIVE ORDER'), what: 'active order card');
      await t.tap(find.text('ACTIVE ORDER'));
      await pumpUntil(t, find.byType(RiderBookingDetailScreen),
          what: 'booking detail');
      await settle(t, 1500);
      noErrors(t, 'detail opened');

      await _tapAction(t, 'Arrived at restaurant');
      await pollUntil(t, () async =>
          (await api.order(orderId))['status'] == 'driver_arrived_at_pickup',
          what: 'driver_arrived_at_pickup');
      expect((await api.order(orderId))['driver_arrived_at_pickup'], isNotNull);

      await _tapAction(t, 'Order picked up');
      await pollUntil(t, () async =>
          (await api.order(orderId))['status'] == 'picked_up',
          what: 'picked_up');
      expect((await api.order(orderId))['picked_up_at'], isNotNull);
    });

    await step('proof of delivery (mock photo) -> complete delivery (COD)',
        () async {
      // A tap is ignored while the previous status update is still refreshing
      // ("already updating"), so retry until the proof section opens.
      for (var attempt = 0; attempt < 4 && find.text('Gallery').evaluate().isEmpty; attempt++) {
        await _tapAction(t, 'Arrived at customer', confirm: false);
        await settle(t, 1500);
      }
      await pumpUntil(t, find.text('Gallery'), what: 'proof upload section');
      // Completing without proof must be refused client-side.
      await _tapAction(t, 'Complete delivery', confirm: false);
      await settle(t, 800);
      expect((await api.order(orderId))['status'], 'picked_up');
      await t.ensureVisible(find.text('Gallery'));
      await t.tap(find.text('Gallery'));
      await settle(t, 800);
      final btn = find.textContaining('Image(s)');
      expect(btn, findsWidgets, reason: 'upload button after picking a photo');
      await t.ensureVisible(btn.first);
      await t.tap(btn.first);
      await pumpUntil(t, find.text('Upload Proof'), what: 'upload confirm');
      await t.tap(find.widgetWithText(ElevatedButton, 'Upload').last);
      await pollUntil(t, () async {
        final o = await api.order(orderId);
        return (o['proof_images'] as List?)?.isNotEmpty ?? false;
      }, what: 'proof_images stored');
      final o = await api.order(orderId);
      expect(o['proof_uploaded_at'], isNotNull);
      await settle(t, 1500);

      await _tapAction(t, 'Complete delivery', confirm: false);
      await pumpUntil(t, find.text('Cash collected'), what: 'COD dialog');
      await t.tap(find.text('Cash collected'));
      await pumpUntil(t, find.text('Update Status'), what: 'confirm dialog');
      await t.tap(find.widgetWithText(ElevatedButton, 'Update'));
      await pollUntil(t, () async =>
          (await api.order(orderId))['status'] == 'completed',
          what: 'completed');
      final done = await api.order(orderId);
      expect(done['completed_at'], isNotNull);
      expect(done['payment_status'], 'paid'); // cash collected on delivery
      await settle(t, 1500);
      // Rating dialog for the customer: skip it.
      if (find.text('Skip').evaluate().isNotEmpty) {
        await t.tap(find.text('Skip'));
        await settle(t, 800);
      }
      noErrors(t, 'after complete');
    });

    await step('earnings + wallet math after completion (API)', () async {
      final o = await api.order(orderId);
      final fare = double.parse('${o['actual_fare'] ?? o['estimated_fare']}');
      final share = double.parse('${o['driver_share']}');
      final platform = double.parse('${o['platform_share']}');
      expect(share + platform, closeTo(fare, 0.011));
      expect(share, closeTo(fare * 0.7, 0.011));
      final e = await api.earnings('all');
      final s = e['summary'];
      expect(s['completed_trips'], (earningsStart['completed_trips'] as num) + 1);
      expect(
        (s['total_earnings'] as num).toDouble(),
        closeTo((earningsStart['total_earnings'] as num).toDouble() + share, 0.011),
      );
      final entry = (e['entries'] as List)
          .firstWhere((x) => x['order_id'] == orderId);
      expect((entry['earnings'] as num).toDouble(), closeTo(share, 0.011));
      // Cash order: the rider's only wallet movement is the hold debit.
      final end = await api.walletBalance();
      final hold = double.parse(
          (walletStart - end).toStringAsFixed(2));
      expect(hold, greaterThan(0));
      expect(hold, closeTo(fare * 0.3 < 10 ? 10 : fare * 0.3, 0.011));
    });

    expect(failures, isEmpty, reason: 'Failed steps: $failures');
  });

  // -------------------------------------------------------------------------
  testWidgets('rider leaves an accepted booking (refund + order passed on)',
      (t) async {
    _tester = t;
    failures.clear();
    assertLocalApi();
    installFakeImagePicker();
    await api.cancelAllOpenOrders();

    final orderId = await api.createOrder();
    await api.merchantMarkReady(orderId);
    final walletBefore = await api.walletBalance();
    await api.riderAcceptViaApi(orderId);
    final walletHeld = await api.walletBalance();
    expect(walletHeld, lessThan(walletBefore), reason: 'hold charged on accept');

    await signInRider(t);
    await tapRiderTab(t, 'Bookings');

    await step('rider sees the active order and opens it', () async {
      if (find.text('List View').evaluate().isNotEmpty) {
        await t.tap(find.text('List View').first);
        await settle(t, 800);
      }
      await pumpUntil(t, find.text('ACTIVE ORDER'),
          pumps: 120, what: 'ACTIVE ORDER card');
      await t.tap(find.text('ACTIVE ORDER'));
      await pumpUntil(t, find.byType(RiderBookingDetailScreen),
          what: 'booking detail');
      await settle(t, 1200);
    });

    await step('Cancel Order -> reason dialog -> released to other riders + refund', () async {
      final cancelBtn = find.widgetWithText(OutlinedButton, 'Cancel Order');
      await pumpUntil(t, cancelBtn, what: 'Cancel Order button');
      await t.ensureVisible(cancelBtn);
      await t.tap(cancelBtn);
      await pumpUntil(t, find.text('Keep Order'), what: 'cancel dialog');
      // Empty reason must not cancel the order.
      await t.tap(find.widgetWithText(ElevatedButton, 'Cancel Order').last);
      await settle(t, 800);
      expect((await api.order(orderId))['status'], 'accepted',
          reason: 'cancelling without a reason must be refused');
      await t.enterText(find.byType(TextField).last, 'Customer not reachable');
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.widgetWithText(ElevatedButton, 'Cancel Order').last);
      await pollUntil(t, () async =>
          (await api.order(orderId))['driver_id'] == null,
          what: 'order released on server');
      final o = await api.order(orderId);
      // Backing out before pickup hands the order to other riders: it is not
      // cancelled for the customer or the store.
      expect(o['status'], anyOf('ready_for_pickup', 'searching_driver'));
      expect(o['cancelled_at'], isNull);
      // The held shipping fee goes back to the rider's wallet.
      expect(await api.walletBalance(), closeTo(walletBefore, 0.001));
      final tx = await api.walletTx();
      expect(tx.first['type'], 'credit');
      expect('${tx.first['description']}', contains('#$orderId'));
      await settle(t, 1500);
      noErrors(t, 'after cancel');
    });

    await step('rider is free to take a new booking afterwards', () async {
      await api.setStatus(orderId, 'cancelled',
          token: await api.admin, reason: 'e2e cleanup');
      final next = await api.createOrder();
      await api.merchantMarkReady(next);
      await api.riderAcceptViaApi(next); // would 409 if a stale active order lingered
      expect((await api.order(next))['status'], 'accepted');
      await api.setStatus(next, 'cancelled',
          token: await api.admin, reason: 'e2e cleanup');
    });

    expect(failures, isEmpty, reason: 'Failed steps: $failures');
  });

  // -------------------------------------------------------------------------
  testWidgets('rider <-> customer chat on an active order + support chat',
      (t) async {
    _tester = t;
    failures.clear();
    assertLocalApi();
    installFakeImagePicker();
    await api.cancelAllOpenOrders();

    final orderId = await api.createOrder();
    await api.merchantMarkReady(orderId);
    await api.riderAcceptViaApi(orderId);

    await signInRider(t);
    await tapRiderTab(t, 'Bookings');
    if (find.text('List View').evaluate().isNotEmpty) {
      await t.tap(find.text('List View').first);
      await settle(t, 800);
    }
    await pumpUntil(t, find.text('ACTIVE ORDER'), what: 'ACTIVE ORDER card');
    await t.tap(find.text('ACTIVE ORDER'));
    await pumpUntil(t, find.byType(RiderBookingDetailScreen),
        what: 'booking detail');
    await settle(t, 1200);

    Future<int> conversationId() async {
      final r = await api.call('GET', '/chat/conversations/order/$orderId',
          token: await api.customer);
      expect(r.statusCode, anyOf(200, 201), reason: 'conversation -> ${r.data}');
      return (api.body(r)['id'] as num).toInt();
    }

    Future<List<String>> storedMessages(int cid) async {
      final r = await api.call('GET', '/chat/conversations/$cid/messages',
          token: await api.customer);
      expect(r.statusCode, 200, reason: 'messages -> ${r.data}');
      final page = api.body(r);
      final list = (page is Map ? page['data'] : page) as List;
      return list.map((m) => '${m['content']}').toList();
    }

    await step('rider sends a chat message -> stored for the customer', () async {
      final fab = find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.byIcon(Icons.chat_bubble_outline));
      await pumpUntil(t, fab, what: 'chat button');
      await t.tap(fab.first);
      await pumpUntil(t, find.byType(RiderChatScreen), what: 'chat screen');
      final field = find.descendant(
          of: find.byType(RiderChatScreen), matching: find.byType(TextField));
      await pumpUntil(t, field, what: 'chat input');
      await settle(t, 1500);
      await t.enterText(field.last, 'Hello from the rider e2e');
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.byIcon(Icons.send).last);
      final cid = await conversationId();
      await pollUntil(t, () async =>
          (await storedMessages(cid)).contains('Hello from the rider e2e'),
          what: 'rider message stored');
      await pumpUntil(t, find.text('Hello from the rider e2e'),
          pumps: 80, what: 'own message shown in the chat list');
      noErrors(t, 'after rider chat send');
    });

    await step('customer message (API) appears in the rider chat UI', () async {
      final cid = await conversationId();
      final r = await api.call('POST', '/chat/conversations/$cid/messages',
          token: await api.customer,
          data: {'message': 'Hi rider, I am at the gate'});
      expect(r.statusCode, anyOf(200, 201), reason: 'customer send -> ${r.data}');
      await pumpUntil(t, find.text('Hi rider, I am at the gate'),
          pumps: 160, what: 'customer message in rider UI (poll)');
      noErrors(t, 'after customer message');
    });

    await step('empty chat message is not sent', () async {
      final cid = await conversationId();
      final before = (await storedMessages(cid)).length;
      final field = find.descendant(
          of: find.byType(RiderChatScreen), matching: find.byType(TextField));
      await t.enterText(field.last, '   ');
      await t.tap(find.byIcon(Icons.send).last);
      await settle(t, 1200);
      expect((await storedMessages(cid)).length, before);
    });

    await step('customer service chat files a support ticket', () async {
      NotificationNavigationService.navigatorKey.currentState!
          .pushNamed(MainRoutes.riderCustomerServiceChat);
      await pumpUntil(t, find.byType(RiderCustomerServiceChatScreen),
          what: 'customer service chat');
      await settle(t, 1500);
      final field = find.descendant(
          of: find.byType(RiderCustomerServiceChatScreen),
          matching: find.byType(TextField));
      await t.enterText(field, 'E2E support question about my earnings');
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.byIcon(Icons.send_rounded));
      late List tickets;
      await pollUntil(t, () async {
        final r = await api.call('GET', '/support/tickets',
            token: await api.rider);
        final d = api.body(r);
        tickets = (d is Map ? d['data'] : d) as List? ?? const [];
        return tickets.any((x) =>
            '${x['description']}'.contains('E2E support question'));
      }, what: 'support ticket stored');
      await settle(t, 1200);
      expect(find.text('E2E support question about my earnings'), findsWidgets);
      noErrors(t, 'after support chat');
    });

    await api.setStatus(orderId, 'cancelled',
        token: await api.admin, reason: 'e2e cleanup');
    expect(failures, isEmpty, reason: 'Failed steps: $failures');
  });

  // -------------------------------------------------------------------------
  testWidgets('earnings screens + history match the API after a delivery',
      (t) async {
    _tester = t;
    failures.clear();
    assertLocalApi();
    installFakeImagePicker();
    await api.cancelAllOpenOrders();

    final orderId = await api.createOrder();
    await api.merchantMarkReady(orderId);
    await api.riderAcceptViaApi(orderId);
    await api.riderCompleteViaApi(orderId);
    final o = await api.order(orderId);
    final share = double.parse('${o['driver_share']}');
    final e = await api.earnings('all');
    final total = (e['summary']['total_earnings'] as num).toDouble();
    final trips = e['summary']['completed_trips'] as int;
    expect(share, greaterThan(0));
    String php(double v) => 'PHP ${v.toStringAsFixed(2)}';

    await signInRider(t);

    await step('My Earnings shows API total, trip count and the order entry',
        () async {
      NotificationNavigationService.navigatorKey.currentState!
          .pushNamed(MainRoutes.riderEarnings);
      await pumpUntil(t, find.text('All Time'), what: 'earnings period chips');
      // The period chips scroll horizontally; 'All Time' can start off-screen.
      await t.ensureVisible(find.text('All Time'));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('All Time'));
      await pumpUntil(t, find.text(php(total)), pumps: 80,
          what: 'total ${php(total)}');
      expect(find.text('$trips trips'), findsWidgets);
      expect(find.textContaining('#$orderId'), findsWidgets);
      expect(find.text(php(share)), findsWidgets);
      noErrors(t, 'earnings screen');
      NotificationNavigationService.navigatorKey.currentState!.pop();
      await settle(t, 800);
    });

    await step('Earnings Insights total matches API (month)', () async {
      final m = await api.earnings('month');
      final mTotal = (m['summary']['total_earnings'] as num).toDouble();
      NotificationNavigationService.navigatorKey.currentState!
          .pushNamed(MainRoutes.riderEarningsInsights);
      await pumpUntil(t, find.text(php(mTotal)), pumps: 80,
          what: 'insights total ${php(mTotal)}');
      noErrors(t, 'insights screen');
      NotificationNavigationService.navigatorKey.currentState!.pop();
      await settle(t, 800);
    });

    await step('History lists the completed order and opens its detail',
        () async {
      await tapRiderTab(t, 'History');
      await settle(t, 2000);
      dumpScreen(t, 'history');
      expect(find.byType(RiderHistoryView), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
      // The completed order's card shows its id and the driver share.
      final idText = find.text('$orderId');
      expect(idText, findsWidgets);
      expect(find.text(php(share)), findsWidgets,
          reason: 'history card earnings must equal the API driver_share');
      await t.tap(idText.first);
      await pumpUntil(t, find.byType(RiderBookingDetailScreen),
          what: 'history -> booking detail');
      await settle(t, 1500);
      noErrors(t, 'history detail');
      NotificationNavigationService.navigatorKey.currentState!.pop();
      await settle(t, 800);
      noErrors(t, 'history');
    });

    expect(failures, isEmpty, reason: 'Failed steps: $failures');
  });

  // -------------------------------------------------------------------------
  testWidgets('wallet: top-up + withdraw validation, no money moves locally',
      (t) async {
    _tester = t;
    failures.clear();
    assertLocalApi();
    installFakeImagePicker();
    final riderTok = await api.rider;
    final balance0 = await api.walletBalance();
    final txCount0 = (await api.walletTx()).length;

    await step('API validation (top-up / withdraw)', () async {
      // `throttle:N,1` shares ONE per-user counter across top-up/withdraw (3 per
      // minute), so use exactly 3 calls here and wait for the window to reset.
      Future<int?> status(String path, Map<String, dynamic> body) async =>
          (await api.call('POST', path, token: riderTok, data: body)).statusCode;
      expect(await status('/wallets/my/topup', {'amount': 5}), 422);
      expect(await status('/wallets/my/withdraw',
          {'amount': 9.99, 'withdrawal_method': 'gcash'}), 422);
      expect(await status('/wallets/my/withdraw',
          {'amount': 50, 'withdrawal_method': 'paypal'}), 422);
      expect(await api.walletBalance(), closeTo(balance0, 0.001));
      expect((await api.walletTx()).length, txCount0);
      await Future<void>.delayed(const Duration(seconds: 63));
    });

    await signInRider(t);

    await step('wallet screen: balance equals API, top-up dialog validation + fee',
        () async {
      await tapRiderTab(t, 'More');
      final open = find.text('Open wallet');
      await pumpUntil(t, open, what: 'Open wallet row');
      await t.ensureVisible(open.last);
      await t.tap(open.last);
      await pumpUntil(t, find.text('Top up'), what: 'wallet screen');
      await settle(t, 1500);
      dumpScreen(t, 'wallet screen');
      final b = balance0;
      final grouped = b.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
      final plain = b.toStringAsFixed(2);
      final found = find.byWidgetPredicate((w) =>
          w is Text &&
          ((w.data ?? '').contains(grouped) || (w.data ?? '').contains(plain)));
      await pumpUntil(t, found,
          pumps: 80, what: 'wallet balance $grouped / $plain on screen');

      await t.tap(find.text('Top up').last);
      await pumpUntil(t, find.byType(Dialog), what: 'top-up dialog');
      await settle(t, 500);
      final field = find.descendant(
          of: find.byType(Dialog), matching: find.byType(TextFormField));
      final cont = find.widgetWithText(FilledButton, 'Continue to payment');
      Future<void> submit() async {
        FocusManager.instance.primaryFocus?.unfocus();
        await t.pump(const Duration(milliseconds: 500));
        await t.ensureVisible(cont);
        await t.pump(const Duration(milliseconds: 200));
        await t.tap(cont);
        await settle(t, 500);
      }

      await submit();
      expect(find.text('Please enter an amount'), findsOneWidget);
      await t.enterText(field, '5');
      await submit();
      expect(find.text('Minimum amount is PHP 10.00'), findsOneWidget);
      // The input formatter does not accept programmatic jumps from '5' in the
      // test harness, so set the controller directly for the remaining amounts
      // (this still exercises the dialog's validators and fee preview).
      final amountCtrl = t.widget<TextFormField>(field).controller!;
      amountCtrl.text = '200000';
      await t.pump(const Duration(milliseconds: 300));
      await submit();
      expect(find.text('Maximum amount is PHP 100,000.00'), findsOneWidget);
      // Fee preview: 3% on top of the credit, same formula as the backend.
      // The quick-amount chip sets the field and rebuilds the fee summary.
      await t.ensureVisible(find.text('₱100'));
      await t.tap(find.text('₱100'));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('₱100.00'), findsWidgets);
      expect(find.text('₱3.00'), findsWidgets);
      expect(find.text('₱103.00'), findsWidgets);
      // Valid amount reaches the server, which has no gateway locally.
      await submit();
      await settle(t, 3000);
      noErrors(t, 'top-up submit');
      dumpScreen(t, 'after top-up submit');
      expect(find.byType(Dialog), findsWidgets,
          reason: 'dialog stays open when the gateway is unavailable');
      expect(await api.walletBalance(), closeTo(balance0, 0.001));
      expect((await api.walletTx()).length, txCount0);
      // Letters are rejected by the input formatter: the field keeps its old value.
      await t.enterText(field, 'abc');
      await t.pump(const Duration(milliseconds: 300));
      expect(t.widget<TextFormField>(field).controller?.text, '100');
      Navigator.of(t.element(find.byType(Dialog).first), rootNavigator: true)
          .pop();
      await settle(t, 600);
    });

    await step('payout screen: withdraw dialog validation, no money moves',
        () async {
      NotificationNavigationService.navigatorKey.currentState!
          .pushNamed(MainRoutes.riderPayout);
      await pumpUntil(t, find.text('Withdraw'), what: 'payout screen');
      await settle(t, 1500);
      await t.tap(find.text('Withdraw').first);
      await pumpUntil(t, find.text('Withdraw Funds'), what: 'withdraw dialog');
      final amount = find.descendant(
          of: find.byType(AlertDialog), matching: find.byType(TextField));
      final submit = find.widgetWithText(ElevatedButton, 'Withdraw').last;
      Future<void> attempt(String value) async {
        ScaffoldMessenger.of(t.element(find.byType(AlertDialog)))
            .clearSnackBars();
        await t.pump(const Duration(milliseconds: 300));
        await t.enterText(amount, value);
        await t.ensureVisible(submit);
        await t.tap(submit);
        await settle(t, 600);
      }

      await attempt('5');
      expect(find.text('Minimum withdrawal is PHP 10'), findsOneWidget);
      await attempt('0');
      expect(find.text('Minimum withdrawal is PHP 10'), findsWidgets);
      await attempt('${(balance0 + 1000).round()}');
      expect(find.text('Insufficient balance'), findsOneWidget);
      await attempt('50');
      await settle(t, 3000);
      noErrors(t, 'withdraw submit');
      dumpScreen(t, 'after withdraw submit');
      expect(find.text('Withdraw Funds'), findsOneWidget,
          reason: 'dialog stays open when the withdrawal fails');
      expect(find.text('Withdrawal request submitted successfully'), findsNothing);
      expect(await api.walletBalance(), closeTo(balance0, 0.001));
      expect((await api.walletTx()).length, txCount0);
      await t.tap(find.text('Cancel').last);
      await settle(t, 600);
    });

    expect(failures, isEmpty, reason: 'Failed steps: $failures');
  });
}

bool switchValue(WidgetTester t, Finder f) =>
    t.widget<Switch>(f.first).value;

/// Taps one of the big "next action" buttons on the booking detail screen and
/// (optionally) confirms the "Update Status" dialog.
Future<void> _tapAction(WidgetTester t, String title,
    {bool confirm = true}) async {
  final f = find.text(title);
  await pumpUntil(t, f, what: 'action "$title"');
  await t.ensureVisible(f.last);
  await t.pump(const Duration(milliseconds: 300));
  await t.tap(f.last);
  if (confirm) {
    await pumpUntil(t, find.text('Update Status'), what: 'confirm dialog');
    await t.tap(find.widgetWithText(ElevatedButton, 'Update'));
  }
  await settle(t, 1200);
  noErrors(t, 'action $title');
}
