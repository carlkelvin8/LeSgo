import 'package:flutter/material.dart';

import '../widgets.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/constants/routers/app_router.dart';

/// The Inbox shortcut now lives at the top-right of the home header
/// ([LocationHeader]); the wallet keeps the whole row here.
class HomeQuickAccessSection extends StatelessWidget {
  const HomeQuickAccessSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 16),
      ),
      child: QuickAccessCard(
        wide: true,
        iconPath: 'assets/images/homepage/Wallet.svg',
        title: tr(context, 'wallet'),
        subtitle: tr(context, 'pay_orders_lespay'),
        onTap: () => AppRouter.push(context, MainRoutes.lespay),
      ),
    );
  }
}
