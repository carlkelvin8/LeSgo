import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../provider/main/riderside/rider_main_nav_provider.dart';
import '../../../widgets/widgets.dart';
import 'views/rider_profile_view.dart';
import 'views/rider_wallet_view.dart';
import 'views/rider_history_view.dart';
import 'views/rider_mission_view.dart';
import 'views/rider_bookings_view.dart';
import 'views/rider_inbox_view.dart';
import '../../../provider/auth/auth_provider.dart';
import '../../../provider/auth/rider_auth_provider.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/auth/auth_routes.dart';

// Actually, RegisterScaffold is specific to registration. Standard Scaffold is better for Main Screen.

class RiderMainScreen extends ConsumerStatefulWidget {
  const RiderMainScreen({super.key});

  @override
  ConsumerState<RiderMainScreen> createState() => _RiderMainScreenState();
}

class _RiderMainScreenState extends ConsumerState<RiderMainScreen> {
  @override
  void initState() {
    super.initState();
    // Check authentication on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  void _checkAuthentication() {
    final authState = ref.read(riderAuthProvider);
    print('🔐 RiderMainScreen: Checking authentication');
    print('🔐 Is logged in: ${authState.isLoggedIn}');
    print('🔐 User: ${authState.user?.email}');
    
    if (!authState.isLoggedIn || authState.user == null) {
      print('❌ Not authenticated, redirecting to login');
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
    } else {
      print('✅ Authenticated as: ${authState.user!.email}, Role: ${authState.user!.role}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final navStack = ref.watch(riderNavProvider);
    final currentNav = navStack.last;
    final isMission = currentNav == RiderNavType.mission;

    return PopScope(
      // Allow the system to close the app only when we're at the root tab
      canPop: navStack.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(riderNavProvider.notifier).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: isMission
            ? _buildBody(currentNav)
            : SafeArea(
                child: Column(
                  children: [
                    HomeHeader(
                      action: currentNav == RiderNavType.profile
                          ? GestureDetector(
                              onTap: () => _showLogoutDialog(context, ref),
                              child: const Icon(
                                Icons.exit_to_app_rounded,
                                color: Color(0xFFE53935),
                                size: 26,
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
        // Logout and clear token
        await ref.read(riderAuthProvider.notifier).logout();
        if (context.mounted) {
          ref.read(authViewProvider.notifier).state = AuthView.welcome;
          AppRouter.pushAndRemoveUntil(context, AuthRoutes.auth);
        }
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
      case RiderNavType.wallet:
        return 'Wallet';
      case RiderNavType.mission:
        return 'Mission';
    }
  }
}
