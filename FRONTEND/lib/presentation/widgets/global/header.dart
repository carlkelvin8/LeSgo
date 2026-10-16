import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final Color? textColor;
  final Color? iconColor;

  const AuthHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: ResponsiveUtils.fontSize(context, 20),
            color: iconColor ?? AppColors.foreground(context, Colors.black),
          ),
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
        ),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: textColor ?? AppColors.foreground(context, Colors.black),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 40)),
      ],
    );
  }
}
