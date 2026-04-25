import 'package:flutter/material.dart';

import '../widgets.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/constants/routers/app_router.dart';

class HomeQuickAccessSection extends StatelessWidget {
  const HomeQuickAccessSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16.0),
        vertical: ResponsiveUtils.spacing(context, 16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuickAccessCard(
            iconPath: 'assets/images/homepage/Inbox.svg',
            title: 'Inbox',
            subtitle: 'Receive messages about your orders.',
            onTap: () {
              AppRouter.push(context, MainRoutes.inbox);
            },
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 16)),
          QuickAccessCard(
            iconPath: 'assets/images/homepage/Wallet.svg',
            title: 'LesPay',
            subtitle: 'Pay your orders with your LeSpay wallet.',
            onTap: () {
              AppRouter.push(context, MainRoutes.lespay);
            },
          ),
        ],
      ),
    );
  }
}
