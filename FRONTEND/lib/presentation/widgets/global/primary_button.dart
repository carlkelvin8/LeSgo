import 'package:flutter/material.dart';
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
    
    return SizedBox(
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.spacing(context, 12),
            horizontal: ResponsiveUtils.spacing(context, 24),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
          foregroundColor: backgroundColor == null
              ? Theme.of(context).colorScheme.onPrimary
              : Colors.white,
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: fontSize,
                width: fontSize,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
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
