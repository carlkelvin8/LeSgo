import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

/// A quiet text link used in the footer of the side menu.
class DrawerTextButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const DrawerTextButton({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 16),
          vertical: ResponsiveUtils.spacing(context, 12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'TT Fors',
            color: AppColors.foreground(context, const Color(0xFF6E6277)),
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
