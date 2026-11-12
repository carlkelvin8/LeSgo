// Merchant side: order lifecycle, store open/close, wallet/withdrawal,
// quick-reply chat. The merchant is driven through the real UI; the customer
// and the rider are simulated through the REST API of a LOCAL throwaway Laravel
// backend, and every UI action is verified through the API afterwards.
//
// Prerequisites (all local, nothing touches staging):
//   cd BACKEND/lesgo-api && DB_DATABASE=$(pwd)/database/e2e_merchant.sqlite \
//     QUEUE_CONNECTION=null php artisan serve --host=127.0.0.1 --port=8001 &
//   python3 RIDERSIDE/integration_test/support/local_sqlite_helper.py \
//     $(pwd)/BACKEND/lesgo-api/database/e2e_merchant.sqlite 8002 &
// Run:
//   cd RIDERSIDE && flutter test integration_test/merchant_order_flow_test.dart \
//     -d <simulator udid> --dart-define=API_BASE_URL=http://127.0.0.1:8001/api
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_analytics_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_main_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/merchant_order_detail_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_lespay_view.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_orders_view.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_profile_view.dart';
import 'package:lezgo_rider/presentation/widgets/main/merchantside/orders/merchant_order_queue_card.dart';

import 'support/merchant_test_support.dart';

final List<String> knownIssues = [];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() {
    // ignore: avoid_print
    print('KNOWN BACKEND ISSUES OBSERVED: $knownIssues');
  });

  testWidgets(
    '1. order lifecycle: accept, ready, driver flow, reject, cancel, earnings',
    timeout: const Timeout(Duration(minutes: 20)),
    (tester) async {
      assertLocalBackend();
      await ensureLocalFixtures();
      final actors = await TestActors.login();
      await signInMerchant(tester);
      await tapMerchantTab(tester, 'Orders');
      await pumpUntil(tester, find.byType(MerchantOrdersView));

      // Each section is independent: a failure is recorded and the next one still runs.
      final failures = <String>[];
      Future<void> step(String name, Future<void> Function() body) async {
        try {
          await body();
        } catch (e) {
          failures.add('$name: $e');
          // ignore: avoid_print
          print('STEP FAILED: $name: $e');
          try {
            await tapMerchantTab(tester, 'Orders');
          } catch (_) {}
        }
      }
      var o1 = 0, o2 = 0, o3 = 0, o4 = 0;
      await step('O1 lifecycle', () async {
      // ---- O1: cash order, accepted from the DETAIL screen -----------------
      o1 = await _newOrder(tester, actors);
      await _openOrdersAndFind(tester, o1);
      expect(
        _inCard(o1, 'New order'),
        findsOneWidget,
        reason: 'new pending order should be labelled "New order"',
      );
      expect(_inCard(o1, 'Accept order'), findsOneWidget);
      expect(_inCard(o1, 'Reject order'), findsOneWidget);
      expect(_inCard(o1, 'PHP 300.00'), findsOneWidget,
          reason: 'FOOD TOTAL on the card must equal 2 x 150');

      // open detail
      await _tapInCard(tester, o1, '#$o1');
      await pumpUntil(tester, find.byType(MerchantOrderDetailScreen));
      await pumpFor(tester, 1200);
      expectNoFrameworkErrors(tester, 'order detail');
      expect(find.text('Pending'), findsWidgets);
      expect(find.textContaining('Test Burger'), findsWidgets);
      expect(find.text('PHP 300.00'), findsWidgets, reason: 'items subtotal');
      expect(find.text('PHP 55.00'), findsWidgets, reason: 'delivery fee');
      expect(find.text('PHP 355.00'), findsWidgets, reason: 'total amount');
      // Merchant has not been given any rider/ready buttons yet.
      expect(find.widgetWithText(ElevatedButton, 'Mark Ready'), findsNothing);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Accept'));
      await pumpFor(tester, 500);
      await _confirmDialog(tester, 'Accept');
      await _waitForApiStatus(tester, actors.merchant, o1, 'searching_driver');
      await pumpUntilGone(tester, find.byType(MerchantOrderDetailScreen),
          reason: 'detail screen pops after accept');
      expectNoFrameworkErrors(tester, 'after accept');
      var api1 = await fetchOrder(actors.merchant, o1);
      expect(api1['accepted_at'], isNull,
          reason: 'accepted_at is the rider acceptance time, not the store');
      expect(api1['ready_for_pickup_at'], isNull);
      // customer sees the order moved on
      expect((await fetchOrder(actors.customer, o1))['status'],
          'searching_driver');

      // card now says preparing and offers Mark ready for pickup
      await _openOrdersAndFind(tester, o1);
      await pumpUntil(
        tester,
        _inCard(o1, 'Preparing · finding rider'),
        reason: 'preparing label',
      );
      expect(_inCard(o1, 'Mark ready for pickup'), findsOneWidget);
      expect(_inCard(o1, 'Cancel order'), findsOneWidget);
      expect(_inCard(o1, 'Reject order'), findsNothing,
          reason: 'cannot "reject" an order that was already accepted');

      // Mark ready from the card
      await _tapInCard(tester, o1, 'Mark ready for pickup');
      await _confirmDialog(tester, 'Mark ready');
      await _waitForApiStatus(tester, actors.merchant, o1, 'ready_for_pickup');
      api1 = await fetchOrder(actors.merchant, o1);
      expect(api1['ready_for_pickup_at'], isNotNull);
      await pumpUntil(tester, _inCard(o1, 'Ready for pickup'),
          reason: 'ready label');
      expect(_inCard(o1, 'Mark ready for pickup'), findsNothing);

      // ---- driver takes over (API) ----------------------------------------
      await driverAccept(actors.rider, o1);
      api1 = await fetchOrder(actors.merchant, o1);
      expect(api1['status'], 'accepted');
      expect(api1['driver_id'], isNotNull);
      expect(api1['accepted_at'], isNotNull);
      expect(api1['ready_for_pickup_at'], isNotNull,
          reason: 'ready flag must survive rider acceptance');
      await _refreshOrders(tester);
      await _openOrdersAndFind(tester, o1);
      await pumpUntil(tester, _inCard(o1, 'Ready for pickup · rider assigned'));
      expect(_inCard(o1, 'Cancel order'), findsNothing,
          reason: 'merchant may not cancel once a rider is assigned');
      // The merchant's "cancel" via API is refused too.
      final refused = await setStatus(actors.merchant, o1, 'cancelled',
          reason: 'too late');
      expect(refused.ok, isFalse, reason: 'cancel after rider assigned: $refused');

      await driverPickUp(actors.rider, o1);
      await _refreshOrders(tester);
      await pumpUntil(tester, _inCard(o1, 'Out for delivery'),
          reason: 'out for delivery label');
      expect((await fetchOrder(actors.customer, o1))['status'], 'picked_up');

      await driverComplete(actors.rider, o1);
      await _refreshOrders(tester);
      await pumpUntil(tester, _inCard(o1, 'Delivered'),
          reason: 'delivered label');
      api1 = await fetchOrder(actors.merchant, o1);
      expect(api1['status'], 'completed');
      expect(api1['completed_at'], isNotNull);
      expect(api1['picked_up_at'], isNotNull);
      expect(api1['payment_status'], 'paid',
          reason: 'cash order is marked paid once delivered');
      final cust1 = await fetchOrder(actors.customer, o1);
      expect(cust1['status'], 'completed');
      expect(cust1['payment_status'], 'paid');

      });
      await step('O2 reject', () async {
      // ---- O2: pending order REJECTED with a reason -----------------------
      o2 = await _newOrder(tester, actors);
      await _openOrdersAndFind(tester, o2);
      await _tapInCard(tester, o2, 'Reject order');
      await pumpUntil(tester, find.text('Reject Order'));
      // Confirm is disabled until a reason is chosen.
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Confirm');
      expect(tester.widget<ElevatedButton>(confirmBtn).onPressed, isNull,
          reason: 'cannot reject without picking a reason');
      await tester.tap(find.byType(DropdownButton<String>));
      await pumpFor(tester, 500);
      await tester.tap(find.text('Out of stock').last);
      await pumpFor(tester, 400);
      await tester.tap(confirmBtn);
      await _waitForApiStatus(tester, actors.merchant, o2, 'cancelled');
      final api2 = await fetchOrder(actors.merchant, o2);
      expect(api2['cancel_reason'], 'Out of stock');
      expect(api2['cancelled_at'], isNotNull);
      expect(api2['driver_id'], isNull);
      final cust2 = await fetchOrder(actors.customer, o2);
      expect(cust2['status'], 'cancelled');
      expect(cust2['cancel_reason'], 'Out of stock',
          reason: 'customer must be able to read why the store refused');
      await _openOrdersAndFind(tester, o2);
      await pumpUntil(tester, _inCard(o2, 'Cancelled'));
      // a rider can no longer take it
      expect((await setStatus(actors.rider, o2, 'accepted')).ok, isFalse);

      });
      await step('O3 cancel after accept', () async {
      // ---- O3: accepted, then CANCELLED by the store ----------------------
      o3 = await _newOrder(tester, actors);
      await _openOrdersAndFind(tester, o3);
      await _tapInCard(tester, o3, 'Accept order');
      await _confirmDialog(tester, 'Accept');
      await _waitForApiStatus(tester, actors.merchant, o3, 'searching_driver');
      await _openOrdersAndFind(tester, o3);
      await pumpUntil(tester, _inCard(o3, 'Cancel order'));
      await _tapInCard(tester, o3, 'Cancel order');
      await pumpUntil(tester, find.text('Cancel Order'));
      await tester.tap(find.byType(DropdownButton<String>));
      await pumpFor(tester, 500);
      await tester.tap(find.text('Too busy to fulfill order').last);
      await pumpFor(tester, 400);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
      await _waitForApiStatus(tester, actors.merchant, o3, 'cancelled');
      final api3 = await fetchOrder(actors.merchant, o3);
      expect(api3['cancel_reason'], 'Too busy to fulfill order');
      expect((await fetchOrder(actors.customer, o3))['status'], 'cancelled');

      });
      await step('O4 mark ready from detail', () async {
      // ---- O4: accepted from the card, "Mark Ready" from the DETAIL screen --
      o4 = await _newOrder(tester, actors, quantity: 1);
      await _openOrdersAndFind(tester, o4);
      await _tapInCard(tester, o4, 'Accept order');
      await _confirmDialog(tester, 'Accept');
      await _waitForApiStatus(tester, actors.merchant, o4, 'searching_driver');
      await _openOrdersAndFind(tester, o4);
      await _tapInCard(tester, o4, '#$o4');
      await pumpUntil(tester, find.byType(MerchantOrderDetailScreen));
      await pumpFor(tester, 1200);
      expect(find.text('Waiting for Driver'), findsWidgets);
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Mark Ready'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Mark Ready'));
      await pumpFor(tester, 500);
      await _confirmDialog(tester, 'Mark Ready');
      await _waitForApiStatus(tester, actors.merchant, o4, 'ready_for_pickup');
      await pumpUntilGone(tester, find.byType(MerchantOrderDetailScreen));
      await driverAccept(actors.rider, o4);
      await driverPickUp(actors.rider, o4);
      await driverComplete(actors.rider, o4);

      });
      await step('filters and earnings math', () async {
      // ---- list filters & earnings ----------------------------------------
      await _refreshOrders(tester);
      await _searchOrders(tester, '');
      // The app pages through every order; do the same (100 per page).
      final rows = <Map>[];
      for (var page = 1; page < 30; page++) {
        final listed = await api('GET', '/v1/orders',
            token: actors.merchant,
            query: {'partner_id': 1, 'per_page': 100, 'page': page});
        final data = listed.data is Map ? listed.data['data'] : listed.data;
        final batch = (data as List).cast<Map>();
        rows.addAll(batch);
        final meta = listed.json['meta'];
        if (batch.isEmpty || (meta is Map && meta['has_more'] != true)) break;
      }
      int count(bool Function(String) test) =>
          rows.where((r) => test('${r['status']}')).length;
      // Filter chips and the "N orders" line must agree with the API.
      final expectedPerFilter = <String, int>{
        'All': rows.length,
        'Pending': count((s) => s == 'pending'),
        'Completed': count((s) => s == 'completed'),
        'Cancelled': count((s) => s == 'cancelled'),
      };
      for (final entry in expectedPerFilter.entries) {
        await _selectFilter(tester, entry.key);
        final shown = switch (entry.key) {
          'Pending' => 'New',
          _ => entry.key,
        };
        expect(find.text('$shown  ${entry.value}'), findsOneWidget,
            reason: 'chip count for ${entry.key}');
      }
      Future<void> expectCardInFilter(String filter, int id, bool present) async {
        await _selectFilter(tester, filter);
        if (present) {
          await _scrollOrdersToCard(tester, id);
        } else {
          // absent: scroll through the whole list and make sure it never shows up
          for (var i = 0; i < 40 && card(id).evaluate().isEmpty; i++) {
            await tester.drag(_ordersScrollable(), const Offset(0, -400),
                warnIfMissed: false);
            await pumpFor(tester, 100);
          }
        }
        expect(card(id).evaluate().isNotEmpty, present,
            reason: 'order #$id in the "$filter" filter');
      }

      await expectCardInFilter('Completed', o4, true);
      await expectCardInFilter('Cancelled', o3, true);
      await expectCardInFilter('Cancelled', o4, false);
      await _selectFilter(tester, 'All');

      // Analytics numbers (what the Business Overview screen shows) must match
      // the order values the API returned.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MerchantMainScreen)),
        listen: false,
      );
      var expectedRevenue = 0.0;
      var completed = 0, cancelled = 0;
      for (final r in rows) {
        final status = '${r['status']}';
        if (status == 'completed') {
          completed++;
          final items = (r['lesbuy_items'] ?? r['order_items'] ?? []) as List;
          for (final i in items) {
            final unit = num_(i['actual_price'] ?? i['estimated_price']);
            expectedRevenue += unit * num_(i['quantity']);
          }
        } else if (status == 'cancelled') {
          cancelled++;
        }
      }
      container.invalidate(merchantAnalyticsPeriodProvider);
      await pumpFor(tester, 1500);
      final summary = container.read(merchantAnalyticsSummaryProvider).value;
      expect(summary, isNotNull);
      expect(summary!.completedOrders, completed);
      expect(summary.cancelledOrders, cancelled);
      expect(summary.totalRevenue, closeTo(expectedRevenue, 0.01),
          reason: 'revenue must be the sum of delivered items (cash order '
              'delivery fees belong to the rider)');
      expect(expectedRevenue, greaterThanOrEqualTo(300 + 150));

      });
      await step('wallet-paid order', () async {
      // ---- wallet-paid order: merchant wallet must be credited --------------
      // A fresh sandbox has no customer wallet yet; create it before topping up.
      await localSql(
        "insert into wallets (user_id, balance, currency, created_at, updated_at) "
        "select 4, 0, 'PHP', datetime('now'), datetime('now') "
        "where not exists (select 1 from wallets where user_id=4)",
      );
      await localSql('update wallets set balance=balance+2000 where user_id=4');
      final merchantWalletBefore = await _merchantWalletBalance(actors.merchant);
      final o5 = await _newOrder(tester, actors,
          paymentMethod: 'wallet', quantity: 2);
      await _openOrdersAndFind(tester, o5);
      await _tapInCard(tester, o5, 'Accept order');
      await _confirmDialog(tester, 'Accept');
      await _waitForApiStatus(tester, actors.merchant, o5, 'searching_driver');
      await _openOrdersAndFind(tester, o5);
      await _tapInCard(tester, o5, 'Mark ready for pickup');
      await _confirmDialog(tester, 'Mark ready');
      await _waitForApiStatus(tester, actors.merchant, o5, 'ready_for_pickup');
      await driverAccept(actors.rider, o5);
      await driverPickUp(actors.rider, o5);
      await driverComplete(actors.rider, o5);
      final api5 = await fetchOrder(actors.merchant, o5);
      expect(api5['payment_status'], 'paid');
      expect(api5['payment_method'], 'wallet');
      final merchantWalletAfter = await _merchantWalletBalance(actors.merchant);
      // Completing an online-paid order pays the store its item subtotal.
      expect(merchantWalletAfter - merchantWalletBefore, closeTo(300, 0.01),
          reason: 'wallet-paid order #$o5 must credit the store PHP 300');
      // The order detail screen of a wallet-paid order advertises the credit.
      await _openOrdersAndFind(tester, o5);
      await _tapInCard(tester, o5, '#$o5');
      await pumpUntil(tester, find.byType(MerchantOrderDetailScreen));
      await pumpFor(tester, 1200);
      expect(find.text('Credited to E-Wallet'), findsOneWidget);
      expectNoFrameworkErrors(tester, 'wallet-paid detail');
      });
      expect(failures, isEmpty, reason: 'failed sections: $failures');
    },
  );

  testWidgets(
    '2. store open/close toggle',
    timeout: const Timeout(Duration(minutes: 10)),
    (tester) async {
      assertLocalBackend();
      await ensureLocalFixtures();
      final actors = await TestActors.login();
      await signInMerchant(tester);
      await tapMerchantTab(tester, 'Profile');
      await pumpUntil(tester, find.byType(MerchantProfileView));
      final status = find.textContaining('Store Status', findRichText: true);
      await pumpUntil(tester, status, reason: 'Store Status row');
      final toggle = find.byType(Switch).first;
      await tester.ensureVisible(toggle);
      await pumpFor(tester, 300);
      expect(find.textContaining('OPEN', findRichText: true), findsWidgets);
      expect(await _partnerIsOpen(actors.merchant), isTrue);

      // CLOSE
      await tester.tap(toggle);
      await _waitForPartnerOpen(tester, actors.merchant, false);
      expect(await _partnerIsOpen(actors.merchant), isFalse);
      expect(
        (await localSql('select is_open from partners where id=1')).first[0],
        0,
      );
      expect(find.textContaining('CLOSED', findRichText: true), findsWidgets);
      // customer-facing view says closed
      final publicView = await api('GET', '/v1/partners/1', token: actors.customer);
      expect(publicView.dataMap['is_open'], anyOf(false, 0));
      // and the closed store rejects a new customer order
      final rejected = await customerCreateOrder(actors.customer);
      expect(rejected.ok, isFalse, reason: 'closed store took an order: $rejected');
      expect(rejected.message.toLowerCase(), contains('closed'));
      final before = (await localSql(
        'select count(*) from orders where partner_id=1',
      )).first[0];
      // reopening from the UI
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);
      await tester.tap(find.byType(Switch).first);
      await _waitForPartnerOpen(tester, actors.merchant, true);
      expect(await _partnerIsOpen(actors.merchant), isTrue);
      final accepted = await customerCreateOrder(actors.customer);
      expect(accepted.ok, isTrue, reason: 'reopened store refused: $accepted');
      expect(
        (await localSql('select count(*) from orders where partner_id=1'))
            .first[0],
        (before as int) + 1,
        reason: 'the refused order must not have been stored',
      );
      // clean up the extra order
      await setStatus(actors.customer, accepted.dataMap['id'] as int, 'cancelled');
      expectNoFrameworkErrors(tester, 'store toggle');
    },
  );

  testWidgets(
    '3. wallet: balance, top-up validation, real withdrawal',
    timeout: const Timeout(Duration(minutes: 10)),
    (tester) async {
      assertLocalBackend();
      await ensureLocalFixtures();
      final actors = await TestActors.login();
      // Known starting balance of PHP 1,000 on the merchant wallet.
      await api('GET', '/v1/wallets/my/wallet', token: actors.merchant);
      await localSql('update wallets set balance=1000 where user_id=2');
      await localSql(
        "update merchant_withdrawal_requests set status='cancelled' "
        "where partner_id=1 and status='pending'",
      );
      expect(await _merchantWalletBalance(actors.merchant), 1000);
      final txBefore = await _walletTxCount(actors.merchant);

      await signInMerchant(tester);
      await tapMerchantTab(tester, 'LeSpay');
      await pumpUntil(tester, find.byType(MerchantLespayView));
      await pumpUntil(tester, find.text('LesPay'));
      await pumpFor(tester, 2500);
      // balance card shows PHP 1000.00 (counter animation settled)
      expect(find.textContaining('1000.00', findRichText: true), findsWidgets,
          reason: 'wallet card should display the API balance');

      // ---- top-up: validation, then the request really reaches the API ----
      await tester.tap(find.widgetWithText(InkWell, 'Top up').first);
      await pumpUntil(tester, find.text('Top up wallet'));
      await tester.tap(find.text('Continue to payment'));
      await pumpFor(tester, 300);
      expect(find.text('Minimum top-up is ₱50'), findsOneWidget);
      await tester.enterText(fieldWith('Amount to add'), '20');
      await pumpFor(tester, 300);
      await tester.ensureVisible(find.text('Continue to payment'));
      await tester.tap(find.text('Continue to payment'));
      await pumpFor(tester, 300);
      expect(find.text('Minimum top-up is ₱50'), findsOneWidget);
      await tester.enterText(fieldWith('Amount to add'), '100');
      await pumpFor(tester, 300);
      expect(find.text('₱3.00'), findsOneWidget, reason: '3% fee on 100');
      await tester.ensureVisible(find.text('Continue to payment'));
      await tester.tap(find.text('Continue to payment'));
      await pumpFor(tester, 2500);
      // The local backend has no payment provider configured: the request must
      // be refused cleanly with a visible message, and no money must move.
      expect(find.textContaining('No payment gateway'), findsWidgets,
          reason: 'user should see why the top-up could not start');
      expect(await _merchantWalletBalance(actors.merchant), 1000);
      expectNoFrameworkErrors(tester, 'top-up');
      await tester.tapAt(const Offset(10, 80));
      await pumpFor(tester, 600);

      // ---- withdrawal sheet validation ------------------------------------
      Future<void> openSheet() async {
        await pumpUntilGone(tester, find.text('Withdraw Earnings'), maxPumps: 20);
        await tester.ensureVisible(find.widgetWithText(InkWell, 'Withdraw').first);
        await tester.tap(find.widgetWithText(InkWell, 'Withdraw').first);
        await pumpUntil(tester, find.text('Withdraw Earnings'));
        await pumpFor(tester, 500);
      }

      Future<void> fill({
        required String amount,
        String number = '09171234567',
        String name = 'Test Merchant',
      }) async {
        await tester.enterText(fieldWith('Withdrawal Amount'), amount);
        await tester.enterText(fieldWith('GCash Number'), number);
        await tester.enterText(fieldWith('Account Name'), name);
        FocusManager.instance.primaryFocus?.unfocus();
        await pumpFor(tester, 300);
      }

      Future<void> submit() async {
        final btn = find.text('Submit Request');
        await tester.ensureVisible(btn);
        await tester.tap(btn);
        await pumpFor(tester, 1500);
      }

      await openSheet();
      expect(find.text('PHP 1000.00'), findsWidgets, reason: 'available balance');
      await submit(); // everything empty
      expect(find.text('Please enter a valid amount'), findsWidgets);
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);

      await fill(amount: '0');
      await submit();
      expect(find.text('Please enter a valid amount'), findsWidgets,
          reason: 'zero amount must be refused');
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);

      await fill(amount: '-50');
      await submit();
      expect(find.text('Please enter a valid amount'), findsWidgets,
          reason: 'negative amount must be refused');
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);

      await fill(amount: '50');
      await submit();
      expect(find.textContaining('Minimum withdrawal amount is PHP 100'),
          findsWidgets);
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);

      await fill(amount: '5000');
      await submit();
      expect(find.textContaining('Insufficient available balance'),
          findsWidgets,
          reason: 'withdrawing more than the wallet holds must be refused');
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);

      await fill(amount: '300', number: '');
      await submit();
      expect(find.text('Please enter account number'), findsWidgets);
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);

      // none of the refused attempts may have touched the wallet
      expect(await _merchantWalletBalance(actors.merchant), 1000);
      expect(
        (await localSql(
          "select count(*) from merchant_withdrawal_requests where partner_id=1 "
          "and status='pending'",
        )).first[0],
        0,
      );

      // ---- a REAL withdrawal of PHP 300 -----------------------------------
      await fill(amount: '300');
      await submit();
      await pumpUntil(tester,
          find.text('Withdrawal request submitted successfully!'),
          reason: 'success snackbar');
      expectNoFrameworkErrors(tester, 'withdrawal submit');
      final rows = await localSql(
        'select id, amount, fee, net_amount, status, payout_method, '
        'payout_account_number, payout_account_name from '
        'merchant_withdrawal_requests where partner_id=1 order by id desc limit 1',
      );
      expect(rows.length, 1);
      final w = rows.first as List;
      expect(num_(w[1]), 300);
      expect(num_(w[2]), 0);
      expect(num_(w[3]), 300);
      expect(w[4], 'pending');
      expect(w[5], 'gcash');
      expect(w[6], '09171234567');
      expect(w[7], 'Test Merchant');
      // ledger math: balance debited immediately, one new debit transaction
      expect(await _merchantWalletBalance(actors.merchant), 700);
      final summary = (await api('GET', '/v1/merchant/withdrawals/summary',
              token: actors.merchant))
          .dataMap;
      expect(num_(summary['available_balance']), 700);
      expect(num_(summary['pending_withdrawals']), 300);
      expect(await _walletTxCount(actors.merchant), txBefore + 1);
      final tx = (await api('GET', '/v1/wallets/my/transactions',
              token: actors.merchant))
          .data as List;
      final newest = Map<String, dynamic>.from(tx.first as Map);
      expect(newest['type'], 'debit');
      expect(num_(newest['amount']), 300);
      // the API does not expose before/after; check the ledger row itself
      final ledger = (await localSql(
        'select balance_before, balance_after from wallet_transactions '
        'where wallet_id=(select id from wallets where user_id=2) '
        'order by id desc limit 1',
      )).first as List;
      expect(num_(ledger[0]), 1000);
      expect(num_(ledger[1]), 700);

      // The wallet screen refreshes to the new balance (scroll the card back
      // into view first: the list is lazy).
      await pumpFor(tester, 2500);
      final walletScroll = find
          .descendant(
            of: find.byType(MerchantLespayView),
            matching: find.byType(Scrollable),
          )
          .first;
      for (var i = 0; i < 4; i++) {
        await tester.drag(walletScroll, const Offset(0, 1500), warnIfMissed: false);
        await pumpFor(tester, 250);
      }
      // the pull-to-refresh above reloads the wallet (balance card shows a
      // skeleton meanwhile)
      await pumpFor(tester, 3000);
      if (find.textContaining('700.00', findRichText: true).evaluate().isEmpty) {
        // ignore: avoid_print
        print('WALLET TEXTS AFTER WITHDRAWAL: ${allTexts()}');
      }
      expect(find.textContaining('700.00', findRichText: true), findsWidgets);

      // history screen lists the pending request
      await tester.ensureVisible(find.text('View Withdrawal History'));
      await tester.tap(find.text('View Withdrawal History'));
      await pumpFor(tester, 2500);
      expect(find.textContaining('300'), findsWidgets);
      expect(find.textContaining('Pending', findRichText: true), findsWidgets,
          reason: 'the new request is listed as pending');
      expectNoFrameworkErrors(tester, 'withdrawal history');
      Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
      await pumpFor(tester, 600);

      // cancelling the pending request through the API gives the money back
      final wid = w[0] as int;
      final cancel = await api('POST', '/v1/merchant/withdrawals/$wid/cancel',
          token: actors.merchant);
      expect(cancel.ok, isTrue, reason: '$cancel');
      expect(await _merchantWalletBalance(actors.merchant), 1000);
    },
  );

  testWidgets(
    '4. quick-reply chat to the customer',
    timeout: const Timeout(Duration(minutes: 10)),
    (tester) async {
      assertLocalBackend();
      await ensureLocalFixtures();
      final actors = await TestActors.login();
      await signInMerchant(tester);
      await tapMerchantTab(tester, 'Orders');
      final o = await _newOrder(tester, actors);
      await _openOrdersAndFind(tester, o);
      await _tapInCard(tester, o, '#$o');
      await pumpUntil(tester, find.byType(MerchantOrderDetailScreen));
      await pumpFor(tester, 1200);
      final quickReply = find.text('Quick Reply');
      await tester.scrollUntilVisible(
        quickReply,
        300,
        scrollable: find.descendant(
          of: find.byType(MerchantOrderDetailScreen),
          matching: find.byType(Scrollable),
        ).first,
      );
      const message = 'Your order is being prepared! 🍳';
      await tester.tap(find.widgetWithText(ActionChip, message));
      await pumpUntilAny(tester, [
        find.text('Message sent!'),
        find.text('Failed to send message'),
      ]);
      expect(find.text('Message sent!'), findsOneWidget,
          reason: 'quick reply to the customer failed in the UI');

      // The customer can read it through the API.
      final conv = await api('GET', '/v1/chat/conversations/order/$o',
          token: actors.customer);
      expect(conv.ok, isTrue, reason: '$conv');
      final convId = conv.dataMap['id'];
      final msgs = await api('GET', '/v1/chat/conversations/$convId/messages',
          token: actors.customer);
      final list = (msgs.data as List).cast<Map>();
      expect(
        list.any((m) => m['content'] == message && m['sender_type'] != 'customer'),
        isTrue,
        reason: 'merchant message was not stored: $msgs',
      );
      // and the customer can answer
      final reply = await api('POST', '/v1/chat/conversations/$convId/messages',
          token: actors.customer, data: {'message': 'Thanks!'});
      expect(reply.ok, isTrue, reason: '$reply');
      await setStatus(actors.customer, o, 'cancelled');
    },
  );

  testWidgets(
    '6. report and block the customer from the order details',
    timeout: const Timeout(Duration(minutes: 10)),
    (tester) async {
      assertLocalBackend();
      await ensureLocalFixtures();
      final actors = await TestActors.login();
      await signInMerchant(tester);
      await tapMerchantTab(tester, 'Orders');
      final o = await _newOrder(tester, actors);
      await _openOrdersAndFind(tester, o);
      await _tapInCard(tester, o, '#$o');
      await pumpUntil(tester, find.byType(MerchantOrderDetailScreen));
      await pumpFor(tester, 1500);

      Future<void> openMenu(String item) async {
        await tester.tap(find.byTooltip('Customer options'));
        await pumpFor(tester, 600);
        await tester.tap(find.text(item));
        await pumpFor(tester, 600);
      }

      // block: confirm dialog, then the customer can no longer order here
      await openMenu('Block customer');
      await _confirmDialog(tester, 'Block');
      await pumpUntil(tester, find.text('Customer blocked.'));
      final blocked = await customerCreateOrder(actors.customer);
      expect(blocked.ok, isFalse,
          reason: 'a blocked customer placed an order: $blocked');
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);

      // the menu now offers to unblock; the customer can order again
      await openMenu('Unblock customer');
      await pumpUntil(tester, find.text('Customer unblocked.'));
      final again = await customerCreateOrder(actors.customer);
      expect(again.ok, isTrue, reason: 'unblocked customer refused: $again');
      await setStatus(actors.customer, again.dataMap['id'] as int, 'cancelled');
      await pumpUntilGone(tester, find.byType(SnackBar), maxPumps: 40);

      // report (without blocking): a support ticket + report row are created
      final ticketsBefore = (await localSql(
        'select count(*) from support_tickets where order_id=?',
        [o],
      )).first[0] as int;
      await openMenu('Report customer');
      await pumpUntil(tester, find.text('Submit report'));
      await tester.tap(find.text('Harassment or bullying'));
      await pumpFor(tester, 300);
      await tester.tap(find.byType(CheckboxListTile)); // untick "Also block"
      await pumpFor(tester, 300);
      await tester.enterText(
          fieldWith('Add details (optional)'), 'integration test report');
      FocusManager.instance.primaryFocus?.unfocus();
      await pumpFor(tester, 300);
      await tester.ensureVisible(find.text('Submit report'));
      await tester.tap(find.text('Submit report'));
      await pumpUntil(tester,
          find.text('Thanks for reporting. Our team will review within 24 hours.'),
          reason: 'report success snackbar');
      expect(
        (await localSql(
          'select count(*) from support_tickets where order_id=?',
          [o],
        )).first[0],
        ticketsBefore + 1,
      );
      // not blocked because the box was unticked
      final stillOk = await customerCreateOrder(actors.customer);
      expect(stillOk.ok, isTrue, reason: 'report without block blocked: $stillOk');
      await setStatus(actors.customer, stillOk.dataMap['id'] as int, 'cancelled');
      await setStatus(actors.customer, o, 'cancelled');
      expectNoFrameworkErrors(tester, 'customer safety');
    },
  );
}

// ===========================================================================
// helpers
// ===========================================================================

Finder card(int id) => find.byWidgetPredicate(
  (w) => w is MerchantOrderQueueCard && w.order.id == id,
  description: 'order card #$id',
);

Finder _inCard(int id, String text) =>
    find.descendant(of: card(id), matching: find.text(text));

Finder _ordersScrollable() => find
    .descendant(
      of: find.byType(MerchantOrdersView),
      matching: find.byType(CustomScrollView),
    )
    .first;

Future<int> _newOrder(
  WidgetTester tester,
  TestActors actors, {
  String paymentMethod = 'cash',
  int quantity = 2,
}) async {
  final r = await customerCreateOrder(
    actors.customer,
    paymentMethod: paymentMethod,
    quantity: quantity,
  );
  expect(r.status, 201, reason: 'customer could not create an order: $r');
  expect(r.dataMap['status'], 'pending');
  return r.dataMap['id'] as int;
}

Future<void> _scrollOrdersToTop(WidgetTester tester) async {
  // Right after a tab tap the view may still be showing its loading skeleton.
  final list = find.descendant(
    of: find.byType(MerchantOrdersView),
    matching: find.byType(CustomScrollView),
  );
  for (var i = 0; i < 24 && list.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  // If another tab is showing, go back to Orders (up to 3 tries).
  for (var t = 0; t < 3 && find.byType(MerchantOrdersView).evaluate().isEmpty; t++) {
    await tapMerchantTab(tester, 'Orders');
    for (var i = 0; i < 12 && list.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }
  if (list.evaluate().isEmpty) {
    // ignore: avoid_print
    print(
      'ORDERS LIST MISSING: main=${find.byType(MerchantMainScreen).evaluate().length} '
      'ordersView=${find.byType(MerchantOrdersView).evaluate().length} '
      'dialogs=${find.byType(AlertDialog).evaluate().length} '
      'scaffolds=${find.byType(Scaffold).evaluate().length} texts=${allTexts()}',
    );
    await pumpUntil(tester, list, reason: 'orders list');
  }
  final scroll = _ordersScrollable();
  final refreshButton = find.widgetWithIcon(IconButton, Icons.refresh_rounded);
  for (var i = 0; i < 30; i++) {
    await tester.drag(scroll, const Offset(0, 1500), warnIfMissed: false);
    await pumpFor(tester, 200);
    if (i >= 3 && refreshButton.evaluate().isNotEmpty) break;
  }
}

Future<void> _refreshOrders(WidgetTester tester) async {
  await _scrollOrdersToTop(tester);
  final refresh = find.widgetWithIcon(IconButton, Icons.refresh_rounded);
  await pumpUntil(tester, refresh);
  // The button is disabled while a load is running.
  for (var i = 0; i < 40; i++) {
    final b = tester.widget<IconButton>(refresh.first);
    if (b.onPressed != null) break;
    await tester.pump(const Duration(milliseconds: 250));
  }
  await tester.tap(refresh.first);
  await pumpFor(tester, 1800);
}

Future<void> _searchOrders(WidgetTester tester, String query) async {
  await _scrollOrdersToTop(tester);
  final search = fieldWith('Search order, customer or item');
  await pumpUntil(tester, search);
  await enterTextReliably(tester, search, query);
  FocusManager.instance.primaryFocus?.unfocus();
  await pumpFor(tester, 500);
}

Future<void> _selectFilter(WidgetTester tester, String label) async {
  await _scrollOrdersToTop(tester);
  // Chips read "<label>  <count>", e.g. "Completed  3" (pending is "New",
  // for-pick-up is "Preparing").
  final shown = switch (label) {
    'Pending' => 'New',
    'For Pick Up' => 'Preparing',
    _ => label,
  };
  final chip = find.descendant(
    of: find.byType(MerchantOrdersView),
    matching: find.byWidgetPredicate(
      (w) => w is Text && RegExp('^$shown  \\d+\$').hasMatch(w.data ?? ''),
      description: 'filter chip "$shown"',
    ),
  );
  if (chip.evaluate().isEmpty) {
    for (var i = 0; i < 20 && chip.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    if (chip.evaluate().isEmpty) {
      // ignore: avoid_print
      print('FILTER CHIP "$shown" MISSING: texts=${allTexts()}');
    }
  }
  await pumpUntil(tester, chip, reason: 'filter chip $shown');
  await tester.ensureVisible(chip.first);
  await tester.tap(chip.first, warnIfMissed: false);
  await pumpFor(tester, 600);
}

Future<void> _scrollOrdersToCard(WidgetTester tester, int id) async {
  final target = card(id);
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find
          .descendant(
            of: _ordersScrollable(),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(target);
  await pumpFor(tester, 300);
}

/// Refresh, filter to this single order and scroll it into view.
Future<void> _openOrdersAndFind(WidgetTester tester, int id) async {
  await tapMerchantTab(tester, 'Orders');
  await _refreshOrders(tester);
  await _selectFilter(tester, 'All');
  await _searchOrders(tester, '$id');
  // The list is lazy: the card only exists once scrolled close enough.
  for (var i = 0; i < 40 && card(id).evaluate().isEmpty; i++) {
    await tester.drag(
      _ordersScrollable(),
      const Offset(0, -250),
      warnIfMissed: false,
    );
    await pumpFor(tester, 250);
  }
  if (card(id).evaluate().isEmpty) {
    final texts = find
        .descendant(
          of: find.byType(MerchantOrdersView),
          matching: find.byType(Text),
        )
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        .take(80)
        .toList();
    // ignore: avoid_print
    print('ORDERS VIEW TEXTS while looking for #$id: $texts');
  }
  expect(card(id), findsOneWidget, reason: 'order #$id card in the list');
  await _scrollOrdersToCard(tester, id);
}

Future<void> _tapInCard(WidgetTester tester, int id, String text) async {
  final target = _inCard(id, text);
  await pumpUntil(tester, target, reason: '"$text" in card #$id');
  await tester.ensureVisible(target.first);
  await pumpFor(tester, 200);
  await tester.tap(target.first, warnIfMissed: false);
  await pumpFor(tester, 500);
}

Future<void> _confirmDialog(WidgetTester tester, String label) async {
  final dialog = find.byType(AlertDialog);
  await pumpUntil(tester, dialog, reason: 'confirm dialog "$label"');
  await tester.tap(
    find.descendant(of: dialog, matching: find.text(label)).last,
  );
  await pumpFor(tester, 400);
}

Future<void> _waitForApiStatus(
  WidgetTester tester,
  String token,
  int id,
  String expected,
) async {
  var last = '';
  for (var i = 0; i < 60; i++) {
    last = '${(await fetchOrder(token, id))['status']}';
    if (last == expected) {
      await pumpFor(tester, 600);
      return;
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Order #$id status is "$last", expected "$expected"');
}

Future<double> _merchantWalletBalance(String token) async {
  final r = await api('GET', '/v1/wallets/my/wallet', token: token);
  return num_(r.dataMap['balance']);
}

Future<int> _walletTxCount(String token) async {
  final r = await api('GET', '/v1/wallets/my/transactions', token: token);
  final d = r.data;
  final list = d is Map ? d['data'] : d;
  return (list as List).length;
}

Future<bool> _partnerIsOpen(String token) async {
  final r = await api('GET', '/v1/partners/1', token: token);
  final v = r.dataMap['is_open'];
  return v == true || v == 1;
}

Future<void> pumpUntilAny(WidgetTester tester, List<Finder> finders) async {
  for (var i = 0; i < 80; i++) {
    if (finders.any((f) => f.evaluate().isNotEmpty)) return;
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Timed out waiting for any of $finders');
}

Future<void> _waitForPartnerOpen(
  WidgetTester tester,
  String token,
  bool open,
) async {
  for (var i = 0; i < 40; i++) {
    if (await _partnerIsOpen(token) == open) {
      await pumpFor(tester, 800);
      return;
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Store did not become ${open ? 'open' : 'closed'} via the toggle');
}
