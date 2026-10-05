import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../provider/main/profile/profile_provider.dart';
import 'invite_friends_sheet.dart';

class ProfileQuickActionsSection extends ConsumerWidget {
  const ProfileQuickActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: AppColors.foreground(context, Colors.black87),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface(context, Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context, Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                _QuickActionTile(
                  icon: Icons.person_add_outlined,
                  title: 'Invite friends',
                  subtitle: 'Share your referral code',
                  onTap: () => InviteFriendsSheet.show(
                    context,
                    referralCode: profile.referralCode,
                    userName: profile.name,
                  ),
                ),
                Divider(
                  height: 1,
                  color: AppColors.foreground(context, Colors.grey.shade200),
                  indent: 56,
                ),
                _QuickActionTile(
                  icon: Icons.location_on_outlined,
                  title: 'Saved Addresses',
                  subtitle: 'Manage delivery addresses',
                  onTap: () => AppRouter.push(context, MainRoutes.addressManagement),
                ),
                Divider(
                  height: 1,
                  color: AppColors.foreground(context, Colors.grey.shade200),
                  indent: 56,
                ),
                _QuickActionTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Order History',
                  subtitle: 'View past orders',
                  onTap: () => AppRouter.push(context, MainRoutes.transactions),
                ),
                Divider(
                  height: 1,
                  color: AppColors.foreground(context, Colors.grey.shade200),
                  indent: 56,
                ),
                _QuickActionTile(
                  icon: Icons.favorite_outline,
                  title: 'Favorites',
                  subtitle: 'Your favorite items',
                  onTap: () => AppRouter.push(context, MainRoutes.favorites),
                ),
                Divider(
                  height: 1,
                  color: AppColors.foreground(context, Colors.grey.shade200),
                  indent: 56,
                ),
                _QuickActionTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'App preferences',
                  onTap: () => AppRouter.push(context, MainRoutes.settings),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accent(context, Color(0xFF5F2D82)).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppColors.accent(context, Color(0xFF5F2D82)),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 14),
          fontWeight: FontWeight.w600,
          color: AppColors.foreground(context, Colors.black87),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 12),
          color: AppColors.foreground(context, Colors.grey[600]!),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.foreground(context, Colors.grey[400]!),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}