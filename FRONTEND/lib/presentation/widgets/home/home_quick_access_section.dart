import 'package:flutter/material.dart';

import '../widgets.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/constants/routers/app_router.dart';

class HomeQuickAccessSection extends StatelessWidget {
  const HomeQuickAccessSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: QuickAccessCard(
              iconPath: 'assets/images/homepage/Inbox.svg',
              title: tr(context, 'inbox'),
              subtitle: tr(context, 'receive_messages_orders'),
              onTap: () => AppRouter.push(context, MainRoutes.inbox),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 16)),
          Expanded(
            child: QuickAccessCard(
              iconPath: 'assets/images/homepage/Wallet.svg',
              title: tr(context, 'wallet'),
              subtitle: tr(context, 'pay_orders_lespay'),
              onTap: () => AppRouter.push(context, MainRoutes.lespay),
            ),
          ),
        ],
      ),
    );
  }
}
