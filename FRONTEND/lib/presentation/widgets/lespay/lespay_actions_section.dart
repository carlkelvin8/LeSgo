import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'lespay_menu_item.dart';
import 'top_up_dialog.dart';
import 'withdraw_dialog.dart';

class LespayActionsSection extends ConsumerWidget {
  const LespayActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        LespayMenuItem(
          iconPath: 'assets/images/lespay/Plus.svg',
          title: 'Top up',
          backgroundColor: const Color(0xFF5F2D82),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const TopUpDialog(),
            );
          },
        ),
        LespayMenuItem(
          iconPath: 'assets/images/lespay/Minus.svg',
          title: 'Withdraw',
          backgroundColor: const Color(0xFF5F2D82),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const WithdrawDialog(),
            );
          },
        ),
        LespayMenuItem(
          iconPath: 'assets/images/lespay/Gift.svg',
          title: 'Redeem Points',
          backgroundColor: const Color(0xFF5F2D82),
          onTap: () {
            SnackBarUtils.showInfo(context, 'Redeem Points feature coming soon!');
          },
        ),
      ],
    );
  }
}
