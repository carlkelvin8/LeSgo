import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/constants/routers/app_router.dart';
import '../widgets.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
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
              title: 'My Profile',
              onTap: () {
                Navigator.pop(context);
                AppRouter.push(context, MainRoutes.profile);
              },
            ),
            DrawerMenuItem(
              iconPath: 'assets/images/navbar/Transaction.svg',
              title: 'Transactions',
              onTap: () {
                Navigator.pop(context);
                AppRouter.push(context, MainRoutes.transactions);
              },
            ),
            DrawerMenuItem(
              iconPath: 'assets/images/navbar/mission.svg',
              title: 'Missions',
              onTap: () {
                Navigator.pop(context);
                AppRouter.push(context, MainRoutes.missions);
              },
            ),

            const Spacer(),

            // Bottom Section with divider and links
            const DrawerDivider(),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

            DrawerTextButton(
              title: 'FAQs',
              onTap: () {
                Navigator.pop(context);
                AppRouter.push(context, MainRoutes.faqs);
              },
            ),
            DrawerTextButton(
              title: 'About LeSgo',
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
