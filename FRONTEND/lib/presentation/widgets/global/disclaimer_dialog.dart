import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import 'primary_button.dart';

class DisclaimerDialog extends StatelessWidget {
  final VoidCallback onOrderNow;
  final VoidCallback onCancel;
  final String description;

  const DisclaimerDialog({
    super.key,
    required this.onOrderNow,
    required this.onCancel,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface(context, Colors.white),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Align(
              alignment: Alignment.center,
              child: Container(
                width: ResponsiveUtils.spacing(context, 48),
                height: ResponsiveUtils.spacing(context, 48),
                decoration: BoxDecoration(
                  color: AppColors.buttonFill(context),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.buttonFill(
                        context,
                      ).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '!',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 24),
                      fontWeight: FontWeight.bold,
                      color: AppColors.onButton(context),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

            // Title
            Text(
              'Disclaimer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: AppColors.foreground(context, Colors.black),
              ),
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 12)),

            // Body content
            // Body content
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: AppColors.foreground(context, Colors.grey[600]!),
                height: 1.5,
              ),
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Order Now Button
            PrimaryButton(text: 'Order Now', onPressed: onOrderNow),

            SizedBox(height: ResponsiveUtils.spacing(context, 12)),

            // Cancel Button
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.foreground(
                  context,
                  Colors.grey[600]!,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
