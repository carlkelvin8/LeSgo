import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/merchantside/merchant_nav_provider.dart';
import '../../../provider/main/merchantside/merchant_orders_provider.dart';

class MerchantBottomNavBar extends ConsumerWidget {
  const MerchantBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNav = ref.watch(merchantNavProvider);
    final pendingCount = ref.watch(merchantPendingOrderCountProvider);
    final selectedColor = const Color(0xFF5F2D82);
    final unselectedColor = Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom:
            ResponsiveUtils.spacing(context, 12) +
            MediaQuery.of(context).padding.bottom,
        top: ResponsiveUtils.spacing(context, 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context, ref,
            type: MerchantNavType.book,
            svgAsset: 'assets/images/navbar/merchant/booking.svg',
            label: 'Book',
            isSelected: currentNav == MerchantNavType.book,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
          _buildNavItem(
            context, ref,
            type: MerchantNavType.orders,
            svgAsset: 'assets/images/navbar/merchant/orders.svg',
            label: 'Orders',
            isSelected: currentNav == MerchantNavType.orders,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
            badgeCount: pendingCount,
          ),
          _buildNavItem(
            context, ref,
            type: MerchantNavType.profile,
            svgAsset: 'assets/images/navbar/merchant/profile.svg',
            label: 'Profile',
            isSelected: currentNav == MerchantNavType.profile,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
          _buildNavItem(
            context, ref,
            type: MerchantNavType.menu,
            svgAsset: 'assets/images/navbar/merchant/menu.svg',
            label: 'Menu',
            isSelected: currentNav == MerchantNavType.menu,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
          _buildNavItem(
            context, ref,
            type: MerchantNavType.lespay,
            svgAsset: 'assets/images/navbar/merchant/star.svg',
            label: 'LeSpay',
            isSelected: currentNav == MerchantNavType.lespay,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref, {
    required MerchantNavType type,
    required String svgAsset,
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
    int badgeCount = 0,
  }) {
    final color = isSelected ? selectedColor : unselectedColor;
    final iconSize = ResponsiveUtils.fontSize(context, 24);

    return InkWell(
      onTap: () => ref.read(merchantNavProvider.notifier).state = type,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 8),
          vertical: ResponsiveUtils.spacing(context, 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  svgAsset,
                  width: iconSize,
                  height: iconSize,
                  allowDrawingOutsideViewBox: true,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 10),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 4)),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 10),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
