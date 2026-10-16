import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../provider/main/profile/profile_provider.dart';
import '../profile/invite_friends_sheet.dart';
import '../widgets.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Drawer(
      backgroundColor: const Color(0xFF642D82),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo Section
            const DrawerLogo(),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Menu Items
            DrawerMenuItem(
              iconPath: 'assets/images/navbar/Profile.svg',
              title: tr(context, 'my_profile'),
              onTap: () {
                Navigator.pop(context);
                AppRouter.push(context, MainRoutes.profile);
              },
            ),
            DrawerMenuItem(
              iconPath: 'assets/images/navbar/Transaction.svg',
              title: tr(context, 'transactions'),
              onTap: () {
                Navigator.pop(context);
                AppRouter.push(context, MainRoutes.transactions);
              },
            ),
            DrawerMenuItem(
              iconPath: 'assets/images/navbar/mission.svg',
              title: tr(context, 'missions'),
              onTap: () {
                Navigator.pop(context);
                AppRouter.push(context, MainRoutes.missions);
              },
            ),
            DrawerMenuItem(
              iconPath: 'assets/images/navbar/Profile.svg',
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

            const Spacer(),

            // Bottom Section with divider and links
            const DrawerDivider(),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

            DrawerTextButton(
              title: tr(context, 'faqs'),
              onTap: () {
                Navigator.pop(context);
                AppRouter.push(context, MainRoutes.faqs);
              },
            ),
            DrawerTextButton(
              title: tr(context, 'about_lesgo'),
              onTap: () {
                Navigator.pop(context);
                AppRouter.push(context, MainRoutes.about);
              },
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

            const DrawerLogoutButton(),

            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          ],
        ),
      ),
    );
  }
}
