import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../provider/main/merchantside/merchant_nav_provider.dart';
import '../../../provider/auth/auth_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/auth/auth_routes.dart';
import 'views/merchant_book_view.dart';
import 'views/merchant_mission_view.dart';
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

class _MerchantMainScreenState extends ConsumerState<MerchantMainScreen> {
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showConfirmDialog(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      onConfirm: () {
        ref.read(authViewProvider.notifier).state = AuthView.welcome;
        AppRouter.pushAndRemoveUntil(context, AuthRoutes.auth);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentNav = ref.watch(merchantNavProvider);
    final isMission = currentNav == MerchantNavType.mission;
    final showMenuFab = currentNav == MerchantNavType.menu;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isMission
          ? const MerchantMissionView()
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
              onAddCategory: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MerchantMenuAddCategoryScreen(),
                  ),
                );
              },
              onAddMenu: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MerchantMenuAddItemScreen(),
                  ),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const MerchantBottomNavBar(),
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
      case MerchantNavType.mission:
        return 'Mission';
    }
  }
}
