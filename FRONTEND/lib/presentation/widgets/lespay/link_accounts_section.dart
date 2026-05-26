import 'package:flutter/material.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'lespay_menu_item.dart';
import 'top_up_dialog.dart';

class LinkAccountsSection extends StatelessWidget {
  const LinkAccountsSection({super.key});

  void _openTopUp(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => TopUpDialog(parentContext: context),
    );
    SnackBarUtils.showInfo(
      context,
      'Add funds via GCash, Maya, or card through Xendit.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LespayMenuItem(
          iconPath: 'assets/images/lespay/Maya.svg',
          title: 'Link PayMaya Account',
          backgroundColor: const Color(0xFF00D632),
          useColorFilter: false,
          addStroke: true,
          onTap: () => _openTopUp(context),
        ),
        LespayMenuItem(
          iconPath: 'assets/images/lespay/Gcash.svg',
          title: 'Link Gcash Account',
          backgroundColor: const Color(0xFF007DFF),
          useColorFilter: false,
          onTap: () => _openTopUp(context),
        ),
        LespayMenuItem(
          iconPath: 'assets/images/lespay/Bank.svg',
          title: 'Link Bank Account',
          backgroundColor: const Color(0xFF5F2D82),
          iconColor: Colors.white,
          onTap: () => _openTopUp(context),
        ),
      ],
    );
  }
}
