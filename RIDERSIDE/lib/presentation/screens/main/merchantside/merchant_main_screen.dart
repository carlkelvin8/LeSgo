import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/auth_navigation.dart';
import '../../../../core/utils/screen_auto_refresh.dart';
import '../../../mixins/auto_refresh_mixin.dart';
import '../../../provider/main/merchantside/merchant_nav_provider.dart';
import '../../../provider/auth/auth_provider.dart';
import '../../../provider/auth/rider_auth_provider.dart';
import '../../../widgets/main/merchantside/merchant_new_order_watcher.dart';
import '../../../widgets/main/merchantside/merchant_prep_timer_sync.dart';
import '../../../widgets/widgets.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/auth/auth_routes.dart';
import '../../../../core/services/notification_navigation_service.dart';
import 'views/merchant_book_view.dart';
import 'views/merchant_lespay_view.dart';
import 'views/merchant_menu_view.dart';
import 'views/merchant_orders_view.dart';
import 'views/merchant_profile_view.dart';
import 'merchant_menu_add_item_screen.dart';
import 'merchant_menu_add_category_screen.dart';
import '../cart_screen.dart';

class MerchantMainScreen extends ConsumerStatefulWidget {
  const MerchantMainScreen({super.key});

  @override
  ConsumerState<MerchantMainScreen> createState() => _MerchantMainScreenState();
}

class _MerchantMainScreenState extends ConsumerState<MerchantMainScreen>
    with WidgetsBindingObserver, AutoRefreshMixin {
  @override
  Duration get autoRefreshInterval => kScreenAutoRefreshInterval;

  @override
  void onAutoRefresh() {
    final currentTab = ref.read(merchantNavProvider);
    refreshMerchantScreen(ref, currentTab);
  }

  @override
  void initState() {
    super.initState();
    // Check authentication after a short delay to allow state to settle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationNavigationService.merchantTabNavigator = (tab) {
        ref.read(merchantNavProvider.notifier).state = tab;
      };
      NotificationNavigationService.onAppReady();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _checkAuthentication();
        }
      });
    });
  }

  void _checkAuthentication() {
    final authState = ref.read(riderAuthProvider);
    AppLogger.auth(
      'MerchantMainScreen auth check: loggedIn=${authState.isLoggedIn}, userId=${authState.user?.id}, partnerId=${authState.user?.partnerId}',
    );

    if (!authState.isLoggedIn || authState.user == null) {
      AppLogger.auth('MerchantMainScreen: redirecting to login');
      // Not authenticated, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(authViewProvider.notifier).state = AuthView.merchantLogin;
          AppRouter.pushReplacement(context, AuthRoutes.auth);
        }
      });
    } else {
      AppLogger.auth(
        'MerchantMainScreen authenticated: userId=${authState.user!.id}, partnerId=${authState.user!.partnerId}',
      );
    }
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

  @override
  Widget build(BuildContext context) {
    ref.listen<RiderAuthState>(riderAuthProvider, (previous, next) {
      if (!mounted) return;
      if ((previous?.isLoggedIn ?? false) && !next.isLoggedIn) {
        navigateToLoginAfterLogout(
          context,
          ref,
          target: AuthViewTarget.merchant,
        );
      }
    });

    final currentNav = ref.watch(merchantNavProvider);
    final isLespay = currentNav == MerchantNavType.lespay;
    final showMenuFab = currentNav == MerchantNavType.menu;

    ref.listen<MerchantNavType>(merchantNavProvider, (previous, next) {
      if (!mounted) return;
      if (previous == next) return;
      refreshMerchantScreen(ref, next, silent: false);
    });

    return MerchantNewOrderWatcher(
      child: MerchantPrepTimerSync(
      child: Scaffold(
      backgroundColor: Colors.white,
      body: isLespay
          ? const MerchantLespayView()
          : SafeArea(
              child: Column(
                children: [
                  HomeHeader(
                    action: currentNav == MerchantNavType.profile
                        ? GestureDetector(
                            onTap: () => _showLogoutDialog(context, ref),
                            child: const Icon(
                              Icons.exit_to_app_rounded,
                              color: Color(0xFFE53935),
                              size: 26,
                            ),
                          )
                        : CartIcon(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CartScreen(),
                                ),
                              );
                            },
                          ),
                  ),
                  Expanded(
                    child: _buildBody(currentNav),
                  ),
                ],
              ),
            ),
      floatingActionButton: showMenuFab
          ? MerchantMenuExpandableFab(
              onAddCategory: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MerchantMenuAddCategoryScreen(),
                  ),
                );
                refreshMerchantScreen(ref, MerchantNavType.menu, silent: false);
              },
              onAddMenu: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MerchantMenuAddItemScreen(),
                  ),
                );
                refreshMerchantScreen(ref, MerchantNavType.menu, silent: false);
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const MerchantBottomNavBar(),
    ),
    ),
    );
  }

  Widget _buildBody(MerchantNavType type) {
    if (type == MerchantNavType.book) {
      return const MerchantBookView();
    }
    if (type == MerchantNavType.profile) {
      return const MerchantProfileView();
    }
    if (type == MerchantNavType.menu) {
      return const MerchantMenuView();
    }
    if (type == MerchantNavType.orders) {
      return const MerchantOrdersView();
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

  String _getTitle(MerchantNavType type) {
    switch (type) {
      case MerchantNavType.book:
        return 'Book';
      case MerchantNavType.orders:
        return 'Orders';
      case MerchantNavType.profile:
        return 'Profile';
      case MerchantNavType.menu:
        return 'Menu';
      case MerchantNavType.lespay:
        return 'LeSpay';
    }
  }
}
