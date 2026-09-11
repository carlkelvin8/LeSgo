import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class RetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isLoading;
  final String actionLabel;
  final IconData actionIcon;

  const RetryWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.isLoading = false,
    this.actionLabel = 'Try Again',
    this.actionIcon = Icons.refresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              'Oops!',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),
            ElevatedButton.icon(
              onPressed: isLoading ? null : onRetry,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(actionIcon),
              label: Text(
                isLoading ? 'Please wait...' : actionLabel,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
