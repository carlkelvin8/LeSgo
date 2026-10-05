import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/provider/main/merchantside/merchant_wallet_provider.dart';
import '../../presentation/provider/main/merchantside/merchant_nav_provider.dart';
import '../../presentation/provider/main/merchantside/merchant_orders_provider.dart';
import '../../presentation/provider/main/merchantside/merchant_reviews_provider.dart';
import '../../presentation/provider/main/merchantside/merchant_profile_provider.dart';
import '../../presentation/provider/main/merchantside/merchant_menu_provider.dart';
import '../../presentation/provider/main/riderside/rider_duty_provider.dart';
import '../../presentation/provider/main/riderside/rider_history_provider.dart';
import '../../presentation/provider/main/riderside/rider_inbox_refresh_provider.dart';
import '../../presentation/provider/main/riderside/rider_main_nav_provider.dart';
import '../../presentation/provider/main/riderside/rider_mission_provider.dart';
import '../../presentation/provider/main/riderside/rider_orders_provider.dart';
import '../../presentation/provider/main/riderside/rider_profile_provider.dart';
import '../../presentation/provider/main/riderside/rider_wallet_provider.dart';

const Duration kScreenAutoRefreshInterval = Duration(seconds: 10);

/// Slower tab refresh for rider main shell — order polling is owned by
/// [RiderOrdersNotifier] when the rider is on duty.
const Duration kRiderMainAutoRefreshInterval = Duration(seconds: 30);

/// Refreshes the visible rider tab without duplicating on-duty order polling.
void refreshRiderScreenOnAutoRefresh(
  WidgetRef ref,
  RiderNavType tab, {
  required bool onDuty,
  bool silent = true,
}) {
  if (tab == RiderNavType.bookings) {
    ref.read(riderWalletProvider.notifier).loadWallet(silent: silent);
    if (!onDuty) {
      ref.read(riderOrdersProvider.notifier).loadOrders(silent: silent);
    }
    return;
  }
  refreshRiderScreen(ref, tab, silent: silent);
}

void refreshRiderScreen(
  WidgetRef ref,
  RiderNavType tab, {
  bool silent = true,
}) {
  switch (tab) {
    case RiderNavType.bookings:
      ref.read(riderOrdersProvider.notifier).loadOrders(silent: silent);
      ref.read(riderWalletProvider.notifier).loadWallet(silent: silent);
      break;
    case RiderNavType.history:
      ref.read(riderHistoryProvider.notifier).loadHistory(silent: silent);
      break;
    case RiderNavType.inbox:
      ref.read(riderInboxRefreshSignalProvider.notifier).state++;
      break;
    case RiderNavType.profile:
      ref.read(riderProfileProvider.notifier).loadProfile(silent: silent);
      break;
    case RiderNavType.wallet:
      ref.read(riderWalletProvider.notifier).loadWallet(silent: silent);
      break;
    case RiderNavType.mission:
      ref.read(riderMissionProvider.notifier).loadMissions(silent: silent);
      break;
    case RiderNavType.more:
      ref.read(riderMissionProvider.notifier).loadMissions(silent: silent);
      ref.read(riderWalletProvider.notifier).loadWallet(silent: silent);
      break;
  }
}

void refreshMerchantScreen(
  WidgetRef ref,
  MerchantNavType tab, {
  bool silent = true,
}) {
  switch (tab) {
    case MerchantNavType.book:
      ref.invalidate(merchantMenuProvider);
      ref.invalidate(merchantMenuItemsProvider);
      break;
    case MerchantNavType.orders:
      ref.invalidate(merchantOrdersProvider);
      break;
    case MerchantNavType.profile:
      ref.invalidate(merchantProfileProvider);
      ref.invalidate(merchantReferralCodeProvider);
      ref.invalidate(merchantMenuItemsProvider);
      ref.invalidate(merchantOrdersProvider);
      ref.invalidate(merchantReviewsDashboardProvider);
      break;
    case MerchantNavType.menu:
      ref.invalidate(merchantMenuProvider);
      ref.invalidate(merchantMenuItemsProvider);
      break;
    case MerchantNavType.lespay:
      ref.read(merchantWalletProvider.notifier).loadWallet(silent: silent);
      break;
  }
}

void refreshAllRiderScreens(WidgetRef ref, {bool silent = true}) {
  if (ref.read(riderDutyProvider)) {
    ref.read(riderOrdersProvider.notifier).loadOrders(silent: silent);
  }
  ref.read(riderWalletProvider.notifier).loadWallet(silent: silent);
  ref.read(riderHistoryProvider.notifier).loadHistory(silent: silent);
  ref.read(riderInboxRefreshSignalProvider.notifier).state++;
  ref.read(riderProfileProvider.notifier).loadProfile(silent: silent);
  ref.read(riderMissionProvider.notifier).loadMissions(silent: silent);
}

void refreshAllMerchantScreens(WidgetRef ref, {bool silent = true}) {
  ref.invalidate(merchantProfileProvider);
  ref.invalidate(merchantReferralCodeProvider);
  ref.invalidate(merchantMenuProvider);
  ref.invalidate(merchantMenuItemsProvider);
  ref.invalidate(merchantOrdersProvider);
  ref.read(merchantWalletProvider.notifier).loadWallet(silent: silent);
}
