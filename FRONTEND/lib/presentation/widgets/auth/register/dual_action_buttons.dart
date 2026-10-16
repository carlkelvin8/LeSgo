import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Reusable dual action buttons (typically for Accept/Decline, Continue/Cancel, etc.)
class DualActionButtons extends StatelessWidget {
  final String primaryText;
  final String secondaryText;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;
  final IconData? primaryIcon;
  final IconData? secondaryIcon;
  final Color? primaryColor;
  final bool isLoading;

  const DualActionButtons({
    super.key,
    required this.primaryText,
    required this.secondaryText,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
    this.primaryIcon,
    this.secondaryIcon,
    this.primaryColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : onSecondaryPressed,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing(context, 12)),
              side: BorderSide(color: AppColors.border(context, Colors.grey[400]!)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (secondaryIcon != null) ...[
                  Icon(secondaryIcon, size: ResponsiveUtils.fontSize(context, 18), color: AppColors.foreground(context, Colors.grey[700]!)),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                ],
                Text(
                  secondaryText,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    color: AppColors.foreground(context, Colors.grey[700]!),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 16)),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : onPrimaryPressed,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing(context, 12)),
              backgroundColor: primaryColor ?? const Color(0xFF5F2D82),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    height: ResponsiveUtils.fontSize(context, 20),
                    width: ResponsiveUtils.fontSize(context, 20),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (primaryIcon != null) ...[
                        Icon(primaryIcon, size: ResponsiveUtils.fontSize(context, 18)),
                        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                      ],
                      Text(
                        primaryText,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
