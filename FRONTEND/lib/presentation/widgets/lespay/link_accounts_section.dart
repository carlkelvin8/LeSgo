import 'package:flutter/material.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'lespay_menu_item.dart';

class LinkAccountsSection extends StatelessWidget {
  const LinkAccountsSection({super.key});

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
          onTap: () {
            SnackBarUtils.showInfo(context, 'Link PayMaya feature coming soon!');
          },
        ),
        LespayMenuItem(
          iconPath: 'assets/images/lespay/Gcash.svg',
          title: 'Link Gcash Account',
          backgroundColor: const Color(0xFF007DFF),
          useColorFilter: false,
          onTap: () {
            SnackBarUtils.showInfo(context, 'Link GCash feature coming soon!');
          },
        ),
        LespayMenuItem(
          iconPath: 'assets/images/lespay/Bank.svg',
          title: 'Link Bank Account',
          backgroundColor: const Color(0xFF5F2D82),
          iconColor: Colors.white,
          onTap: () {
            SnackBarUtils.showInfo(context, 'Link Bank Account feature coming soon!');
          },
        ),
      ],
    );
  }
}
