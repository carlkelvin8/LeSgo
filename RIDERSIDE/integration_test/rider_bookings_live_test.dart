import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lezgo_rider/core/services/api_service.dart';
import 'package:lezgo_rider/core/services/scheduled_payout_service.dart';
import 'package:lezgo_rider/core/constants/routers/main/main_routes.dart';
import 'package:lezgo_rider/core/services/notification_navigation_service.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_history_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_inbox_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_profile_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_wallet_provider.dart';
import 'package:lezgo_rider/presentation/provider/auth/rider_auth_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_orders_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_bookings_view.dart';

import 'support/rider_e2e_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'live rider login loads Bookings and assigned orders',
    (t) async {
      expect(kRiderEmail, isNotEmpty);
      expect(kRiderPassword, isNotEmpty);
      await signInRider(t);
      final view = find.byType(RiderBookingsView);
      expect(view, findsOneWidget);
      final container = ProviderScope.containerOf(t.element(view));
      for (var i = 0; i < 240; i++) {
        final state = container.read(riderOrdersProvider);
        if (state.lastRefreshed != null || state.error != null) break;
        await t.pump(const Duration(milliseconds: 250));
      }
      final loaded = container.read(riderOrdersProvider);
      expect(loaded.error, isNull);
      expect(
        loaded.lastRefreshed,
        isNotNull,
        reason: 'default Bookings tab must fetch without switching tabs',
      );

      // Read the rider scope independently; never create or accept live orders.
      final own = await ApiService.getOrders(mine: true, perPage: 100);
      final driverId = container.read(riderAuthProvider).user!.driverProfileId;
      final expected = reconcileActiveOrders(
        own
            .map((raw) => RiderOrder.fromJson(Map<String, dynamic>.from(raw)))
            .toList(),
        null,
        driverId,
      );
      for (final order in expected) {
        expect(loaded.activeOrders.map((o) => o.id), contains(order.id));
      }
      await container.read(riderOrdersProvider.notifier).loadOrders();
      expect(container.read(riderOrdersProvider).error, isNull);
      noErrors(t, 'live Bookings initial load and refresh');

      for (final tab in ['History', 'Inbox', 'Profile', 'More']) {
        await tapRiderTab(t, tab);
        switch (tab) {
          case 'History':
            await container.read(riderHistoryProvider.notifier).loadHistory();
            expect(container.read(riderHistoryProvider).error, isNull);
          case 'Inbox':
            await container
                .read(riderInboxProvider.notifier)
                .loadConversations();
            expect(container.read(riderInboxProvider).error, isNull);
          case 'Profile':
            await container.read(riderProfileProvider.notifier).loadProfile();
            expect(container.read(riderProfileProvider).error, isNull);
          case 'More':
            await container.read(riderWalletProvider.notifier).loadWallet();
            expect(container.read(riderWalletProvider).error, isNull);
        }
        noErrors(t, 'loaded $tab');
        // ignore: avoid_print
        print('PASS: live $tab loading');
      }

      final nav = NotificationNavigationService.navigatorKey.currentState!;
      for (final route in [
        MainRoutes.riderEarnings,
        MainRoutes.riderEarningsInsights,
        MainRoutes.riderPayout,
        MainRoutes.riderRating,
        MainRoutes.riderQuickStats,
        MainRoutes.riderTripAnalytics,
        MainRoutes.riderPerformance,
        MainRoutes.riderVehicleManagement,
        MainRoutes.riderDocuments,
        MainRoutes.riderSchedule,
        MainRoutes.riderScheduledPayout,
        MainRoutes.riderFaqs,
        MainRoutes.riderOffers,
        MainRoutes.riderLoyalty,
        MainRoutes.riderReferral,
        MainRoutes.riderSecurity,
        MainRoutes.riderSafety,
        MainRoutes.riderNotificationSettings,
        MainRoutes.riderChangePassword,
        MainRoutes.riderDeactivateAccount,
        MainRoutes.riderDeleteAccount,
      ]) {
        final payoutSettings = route == MainRoutes.riderScheduledPayout
            ? await ScheduledPayoutService.load()
            : null;
        nav.pushNamed(route);
        await settle(t, 4500);
        if (payoutSettings != null) {
          for (var i = 0; i < 120; i++) {
            final toggle = find.byType(SwitchListTile);
            if (toggle.evaluate().isNotEmpty &&
                t.widget<SwitchListTile>(toggle).onChanged != null) {
              break;
            }
            await t.pump(const Duration(milliseconds: 250));
          }
          final toggle = t.widget<SwitchListTile>(find.byType(SwitchListTile));
          expect(
            toggle.onChanged,
            isNotNull,
            reason: 'schedule settings must be loaded from the deployed API',
          );
          expect(toggle.value, payoutSettings.enabled);
          expect(find.text('Retry'), findsNothing);
          // ignore: avoid_print
          print('PASS: live scheduled payout API and screen settings agree');
        }
        noErrors(t, 'opened $route');
        // ignore: avoid_print
        print('PASS: screen rendering $route');
        nav.pop();
        await settle(t, 500);
      }
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
