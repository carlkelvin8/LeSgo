import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/riderside/rider_inbox_provider.dart';
import '../../../provider/main/riderside/rider_main_nav_provider.dart';

class RiderBottomNavBar extends ConsumerWidget {
  const RiderBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNav = ref.watch(riderNavProvider).last;
    final unreadCount = ref.watch(riderInboxProvider).unreadCount;
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
            type: RiderNavType.bookings,
            svgAsset: 'assets/images/navbar/riderside/booking.svg',
            label: 'Bookings',
            isSelected: currentNav == RiderNavType.bookings,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
          _buildNavItem(
            context, ref,
            type: RiderNavType.history,
            svgAsset: 'assets/images/navbar/riderside/time.svg',
            label: 'History',
            isSelected: currentNav == RiderNavType.history,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
          _buildNavItemIcon(
            context, ref,
            type: RiderNavType.inbox,
            icon: Icons.chat_bubble_outline,
            label: 'Inbox',
            badgeCount: unreadCount,
            isSelected: currentNav == RiderNavType.inbox,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
          _buildNavItem(
            context, ref,
            type: RiderNavType.profile,
            svgAsset: 'assets/images/navbar/riderside/profile.svg',
            label: 'Profile',
            isSelected: currentNav == RiderNavType.profile,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
          _buildNavItem(
            context, ref,
            type: RiderNavType.wallet,
            svgAsset: 'assets/images/navbar/riderside/wallet.svg',
            label: 'LesPay',
            isSelected: currentNav == RiderNavType.wallet,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
          _buildNavItem(
            context, ref,
            type: RiderNavType.mission,
            svgAsset: 'assets/images/navbar/riderside/star.svg',
            label: 'Mission',
            isSelected: currentNav == RiderNavType.mission,
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
    required RiderNavType type,
    required String svgAsset,
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
  }) {
    final color = isSelected ? selectedColor : unselectedColor;
    final iconSize = ResponsiveUtils.fontSize(context, 24);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label tab',
      child: InkWell(
      onTap: () => ref.read(riderNavProvider.notifier).navigateTo(type),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 4),
          vertical: ResponsiveUtils.spacing(context, 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              svgAsset,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 2)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 10),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // Icon-based nav item (for tabs without SVG assets)
  Widget _buildNavItemIcon(
    BuildContext context,
    WidgetRef ref, {
    required RiderNavType type,
    required IconData icon,
    required String label,
    int badgeCount = 0,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
  }) {
    final color = isSelected ? selectedColor : unselectedColor;
    final iconSize = ResponsiveUtils.fontSize(context, 24);
    final semanticsLabel = badgeCount > 0
        ? '$label tab, $badgeCount unread'
        : '$label tab';

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticsLabel,
      child: InkWell(
      onTap: () => ref.read(riderNavProvider.notifier).navigateTo(type),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 4),
          vertical: ResponsiveUtils.spacing(context, 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: iconSize, color: color),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 9),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 2)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 10),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
