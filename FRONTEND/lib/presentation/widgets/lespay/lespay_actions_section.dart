import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import 'lespay_menu_item.dart';
import 'top_up_dialog.dart';

class LespayActionsSection extends ConsumerWidget {
  const LespayActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        LespayMenuItem(
          iconPath: 'assets/images/lespay/Plus.svg',
          title: 'Top up',
          subtitle: 'GCash, Maya, cards via Xendit',
          backgroundColor: const Color(0xFF5F2D82),
          onTap: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => TopUpDialog(parentContext: context),
            );
          },
        ),
        LespayMenuItem(
          iconPath: 'assets/images/lespay/Gift.svg',
          title: 'Redeem Points',
          subtitle: 'Coming soon',
          backgroundColor: const Color(0xFF5F2D82),
          onTap: () {
            AppRouter.push(context, MainRoutes.loyaltyRedeem);
          },
        ),
      ],
    );
  }
}
