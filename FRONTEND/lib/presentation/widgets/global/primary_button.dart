import 'package:flutter/material.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = ResponsiveUtils.buttonHeight(context);
    final fontSize = ResponsiveUtils.fontSize(context, 16);

    // Brand-purple callers get the shared button fill so primary actions look
    // the same in light and dark mode.
    final isBrand =
        backgroundColor == null || backgroundColor == const Color(0xFF5F2D82);
    final fill = isBrand ? AppColors.buttonFill(context) : backgroundColor!;
    final onFill = isBrand ? AppColors.onButton(context) : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.spacing(context, 12),
            horizontal: ResponsiveUtils.spacing(context, 24),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: fill,
          foregroundColor: onFill,
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: fontSize,
                width: fontSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(onFill),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
