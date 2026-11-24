import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class DrawerDivider extends StatelessWidget {
  const DrawerDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: AppColors.border(context, const Color(0xFFECE5F2)),
      ),
    );
  }
}
