import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';

class SocialLoginButton extends StatelessWidget {
  final String text;
  final String? iconUrl;
  final IconData? iconData;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.text,
    this.iconUrl,
    this.iconData,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = ResponsiveUtils.buttonHeight(context);
    final fontSize = ResponsiveUtils.fontSize(context, 16);
    final iconSize = ResponsiveUtils.fontSize(context, 20);
    
    return SizedBox(
      height: buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.spacing(context, 12),
            horizontal: ResponsiveUtils.spacing(context, 24),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(color: AppColors.border(context, Colors.grey[300]!)),
          backgroundColor: AppColors.surface(context, Colors.white),
          foregroundColor: AppColors.foreground(context, Colors.black87),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconUrl != null)
              Image.network(
                iconUrl!,
                height: iconSize,
                width: iconSize,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(iconData ?? Icons.login, size: iconSize);
                },
              )
            else if (iconData != null)
              Icon(iconData, size: iconSize),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
