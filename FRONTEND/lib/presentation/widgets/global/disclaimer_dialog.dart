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
      backgroundColor: Colors.white,
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
                decoration: const BoxDecoration(
                  color: Color(0xFF9747FF), // Purple color
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x339747FF),
                      blurRadius: 10,
                      offset: Offset(0, 4),
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
                      color: Colors.white,
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
                color: Colors.black,
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
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Order Now Button
            PrimaryButton(
              text: 'Order Now',
              backgroundColor: const Color(0xFF9747FF),
              onPressed: onOrderNow,
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 12)),

            // Cancel Button
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
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
