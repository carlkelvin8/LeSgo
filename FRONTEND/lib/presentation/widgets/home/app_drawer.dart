import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../provider/main/profile/profile_provider.dart';
import '../profile/invite_friends_sheet.dart';
import '../widgets.dart';

/// Light side menu: a small profile row, grouped links, and a quiet footer.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    AppRouter.push(context, route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Drawer(
        backgroundColor: AppColors.surface(context, Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileRow(
                name: profile.name,
                email: profile.email,
                imageUrl: profile.profileImageUrl,
                onTap: () => _go(context, MainRoutes.profile),
              ),
              const DrawerDivider(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(
                    top: ResponsiveUtils.spacing(context, 6),
                  ),
                  children: [
                    const _SectionLabel('ACTIVITY'),
                    DrawerMenuItem(
                      icon: Icons.receipt_long_outlined,
                      title: tr(context, 'order_history'),
                      onTap: () => _go(context, MainRoutes.orderHistory),
                    ),
                    DrawerMenuItem(
                      icon: Icons.swap_horiz_rounded,
                      title: tr(context, 'transactions'),
                      onTap: () => _go(context, MainRoutes.transactions),
                    ),
                    DrawerMenuItem(
                      icon: Icons.favorite_border_rounded,
                      title: tr(context, 'favorites'),
                      onTap: () => _go(context, MainRoutes.favorites),
                    ),
                    const _SectionLabel('REWARDS'),
                    DrawerMenuItem(
                      icon: Icons.local_offer_outlined,
                      title: tr(context, 'offers'),
                      onTap: () => _go(context, MainRoutes.offers),
                    ),
                    DrawerMenuItem(
                      icon: Icons.emoji_events_outlined,
                      title: tr(context, 'missions'),
                      onTap: () => _go(context, MainRoutes.missions),
                    ),
                    DrawerMenuItem(
                      icon: Icons.card_giftcard_rounded,
                      title: tr(context, 'invite_friends'),
                      onTap: () {
                        Navigator.pop(context);
                        InviteFriendsSheet.show(
                          context,
                          referralCode: profile.referralCode,
                          userName: profile.name,
                        );
                      },
                    ),
                    const _SectionLabel('MORE'),
                    DrawerMenuItem(
                      icon: Icons.support_agent_rounded,
                      title: 'Help & support',
                      onTap: () => _go(context, MainRoutes.customerServiceChat),
                    ),
                    DrawerMenuItem(
                      icon: Icons.settings_outlined,
                      title: tr(context, 'settings'),
                      onTap: () => _go(context, MainRoutes.settings),
                    ),
                  ],
                ),
              ),
              const DrawerDivider(),
              Row(
                children: [
                  Expanded(
                    child: DrawerTextButton(
                      title: tr(context, 'faqs'),
                      onTap: () => _go(context, MainRoutes.faqs),
                    ),
                  ),
                  Expanded(
                    child: DrawerTextButton(
                      title: tr(context, 'about_lesgo'),
                      onTap: () => _go(context, MainRoutes.about),
                    ),
                  ),
                ],
              ),
              const DrawerLogoutButton(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  AppInfo.versionLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 11,
                    color: AppColors.foreground(
                      context,
                      const Color(0xFFA899B3),
                    ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(26, 14, 20, 4),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: 10,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w800,
        color: AppColors.foreground(context, const Color(0xFF9A85A8)),
      ),
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.onTap,
  });

  final String name;
  final String email;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, const Color(0xFF5F2D82));
    final displayName = name.trim().isEmpty ? 'My account' : name.trim();
    final initial = displayName.characters.first.toUpperCase();
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Semantics(
      button: true,
      label: 'Profile, $displayName',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            ResponsiveUtils.spacing(context, 18),
            14,
            ResponsiveUtils.spacing(context, 16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: accent.withValues(alpha: 0.12),
                backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
                child: hasImage
                    ? null
                    : Text(
                        initial,
                        style: TextStyle(
                          color: accent,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        color: AppColors.foreground(
                          context,
                          const Color(0xFF2A2032),
                        ),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          color: AppColors.foreground(
                            context,
                            const Color(0xFF7A6C86),
                          ),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.foreground(context, const Color(0xFFB5A6C0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
