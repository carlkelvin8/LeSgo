import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/auth_navigation.dart';
import '../../../../core/utils/screen_auto_refresh.dart';
import '../../../../core/services/order_sound_alert_service.dart';
import '../../../mixins/auto_refresh_mixin.dart';
import '../../../provider/main/riderside/rider_main_nav_provider.dart';
import '../../../provider/main/riderside/rider_mission_provider.dart';
import '../../../provider/main/riderside/rider_history_provider.dart';
import '../../../provider/main/riderside/rider_profile_provider.dart';
import '../../../provider/main/riderside/rider_duty_provider.dart';
import '../../../provider/main/riderside/rider_orders_provider.dart';
import '../../../provider/main/riderside/rider_wallet_provider.dart';
import '../../../provider/main/riderside/rider_inbox_provider.dart';
import '../../../provider/main/riderside/rider_inbox_refresh_provider.dart';
import '../../../widgets/widgets.dart';
import 'views/rider_profile_view.dart';
import 'views/rider_more_view.dart';
import 'views/rider_wallet_view.dart';
import 'views/rider_history_view.dart';
import 'views/rider_mission_view.dart';
import 'views/rider_bookings_view.dart';
import 'views/rider_inbox_view.dart';
import '../../../provider/auth/auth_provider.dart';
import '../../../provider/auth/rider_auth_provider.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/auth/auth_routes.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/services/notification_navigation_service.dart';

// Actually, RegisterScaffold is specific to registration. Standard Scaffold is better for Main Screen.

class RiderMainScreen extends ConsumerStatefulWidget {
  const RiderMainScreen({super.key});

  @override
  ConsumerState<RiderMainScreen> createState() => _RiderMainScreenState();
}

class _RiderMainScreenState extends ConsumerState<RiderMainScreen>
    with WidgetsBindingObserver, AutoRefreshMixin {
  @override
  Duration get autoRefreshInterval => kRiderMainAutoRefreshInterval;

  @override
  void onAutoRefresh() {
    final currentTab = ref.read(riderNavProvider).last;
    final onDuty = ref.read(riderDutyProvider);
    refreshRiderScreenOnAutoRefresh(ref, currentTab, onDuty: onDuty);
  }

  @override
  void initState() {
    super.initState();

    // Check authentication on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationNavigationService.riderTabNavigator = (tab) {
        ref.read(riderNavProvider.notifier).navigateTo(tab);
      };
      NotificationNavigationService.onAppReady();
      
      // Stop persistent notification sound when rider opens app
      OrderSoundAlertService().acknowledgeOrderAlert();
      
      _checkAuthentication();
      ref.read(riderDutyProvider.notifier);
      ref.read(riderWalletProvider.notifier).loadWallet();
      ref.read(riderInboxProvider.notifier).loadConversations(silent: true);
    });
  }

  @override
  void dispose() {
    NotificationNavigationService.riderTabNavigator = null;
    super.dispose();
  }

  void _checkAuthentication() {
    final authState = ref.read(riderAuthProvider);
    AppLogger.auth(
      'RiderMainScreen auth check: loggedIn=${authState.isLoggedIn}, userId=${authState.user?.id}',
    );

    if (!authState.isLoggedIn || authState.user == null) {
      AppLogger.auth('RiderMainScreen: redirecting to login');
      // Not authenticated, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final user = authState.user;
          if (user != null && user.isMerchant) {
            ref.read(authViewProvider.notifier).state = AuthView.merchantLogin;
          } else {
            ref.read(authViewProvider.notifier).state = AuthView.riderLogin;
          }
          AppRouter.pushReplacement(context, AuthRoutes.auth);
        }
      });
    } else if (authState.user!.isRegistrationRestricted) {
      AppLogger.auth(
        'RiderMainScreen: account restricted (registration fee/approval pending)',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppRouter.pushAndRemoveUntil(
          context,
          MainRoutes.registrationFeeStatus,
          arguments: {'target': MainRoutes.riderMain},
        );
      });
    } else {
      AppLogger.auth(
        'RiderMainScreen authenticated: userId=${authState.user!.id}, role=${authState.user!.role}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RiderAuthState>(riderAuthProvider, (previous, next) {
      if (!mounted) return;
      if ((previous?.isLoggedIn ?? false) && !next.isLoggedIn) {
        final user = previous?.user;
        final target = (user?.isMerchant == true || user?.isStaff == true)
            ? AuthViewTarget.merchant
            : AuthViewTarget.rider;
        navigateToLoginAfterLogout(context, ref, target: target);
      }
    });

    final navStack = ref.watch(riderNavProvider);
    final currentNav = navStack.last;
    final isFullBleed = currentNav == RiderNavType.mission;

    // Refresh data when switching to a tab
    ref.listen<List<RiderNavType>>(riderNavProvider, (previous, next) {
      if (!mounted) return;
      final prevTab = previous?.last;
      final newTab = next.last;
      if (prevTab == newTab) return;

      switch (newTab) {
        case RiderNavType.bookings:
          ref.read(riderOrdersProvider.notifier).loadOrders();
          ref.read(riderWalletProvider.notifier).loadWallet();
          break;
        case RiderNavType.more:
          ref.read(riderMissionProvider.notifier).loadMissions();
          ref.read(riderWalletProvider.notifier).loadWallet();
          break;
        case RiderNavType.mission:
          ref.read(riderMissionProvider.notifier).loadMissions();
          break;
        case RiderNavType.history:
          ref.read(riderHistoryProvider.notifier).loadHistory();
          break;
        case RiderNavType.profile:
          ref.read(riderProfileProvider.notifier).loadProfile();
          ref.read(riderMissionProvider.notifier).loadMissions();
          ref.read(riderWalletProvider.notifier).loadWallet();
          break;
        case RiderNavType.wallet:
          ref.read(riderWalletProvider.notifier).loadWallet();
          break;
        case RiderNavType.inbox:
          ref.read(riderInboxProvider.notifier).loadConversations(silent: true);
          ref.read(riderInboxRefreshSignalProvider.notifier).state++;
          break;
      }
    });

    return PopScope(
      // Allow the system to close the app only when we're at the root tab
      canPop: navStack.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(riderNavProvider.notifier).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: isFullBleed
            ? _buildBody(currentNav)
            : SafeArea(
                child: Column(
                  children: [
                    HomeHeader(
                      action: currentNav == RiderNavType.profile
                          ? Semantics(
                              button: true,
                              label: 'Log out',
                              child: GestureDetector(
                                onTap: () => _showLogoutDialog(context, ref),
                                child: const Icon(
                                  Icons.exit_to_app_rounded,
                                  color: Color(0xFFE53935),
                                  size: 26,
                                ),
                              ),
                            )
                          : null,
                    ),
                    Expanded(child: _buildBody(currentNav)),
                  ],
                ),
              ),
        bottomNavigationBar: const RiderBottomNavBar(),
      ),
    );
  }

  Widget _buildBody(RiderNavType type) {
    if (type == RiderNavType.bookings) {
      return const RiderBookingsView();
    }
    if (type == RiderNavType.inbox) {
      return const RiderInboxView();
    }
    if (type == RiderNavType.profile) {
      return const RiderProfileView();
    }
    if (type == RiderNavType.more) {
      return const RiderMoreView();
    }
    if (type == RiderNavType.wallet) {
      return const RiderWalletView();
    }
    if (type == RiderNavType.history) {
      return const RiderHistoryView();
    }
    if (type == RiderNavType.mission) {
      return const RiderMissionView();
    }

    return Center(
      child: Text(
        _getTitle(type),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5F2D82),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showConfirmDialog(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      onConfirm: () async {
        await ref.read(riderAuthProvider.notifier).logout(ref);
      },
    );
  }

  String _getTitle(RiderNavType type) {
    switch (type) {
      case RiderNavType.bookings:
        return 'Bookings';
      case RiderNavType.inbox:
        return 'Inbox';
      case RiderNavType.history:
        return 'History';
      case RiderNavType.profile:
        return 'Profile';
      case RiderNavType.more:
        return 'More';
      case RiderNavType.wallet:
        return 'LesPay';
      case RiderNavType.mission:
        return 'Mission';
    }
  }
}
