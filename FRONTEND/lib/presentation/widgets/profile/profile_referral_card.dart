import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';

class ProfileReferralCard extends StatelessWidget {
  final String referralCode;
  final VoidCallback? onCopy;

  const ProfileReferralCard({
    super.key,
    required this.referralCode,
    this.onCopy,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: referralCode));
    SnackBarUtils.showSuccess(context, 'Referral code copied to clipboard!');
    onCopy?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referral Code',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        GestureDetector(
          onTap: () => _copyToClipboard(context),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.spacing(context, 16),
              vertical: ResponsiveUtils.spacing(context, 14),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  referralCode,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 1.2,
                  ),
                ),
                Icon(
                  Icons.copy,
                  size: ResponsiveUtils.fontSize(context, 20),
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Text(
          'Earn points by referring LeSgo to your friends and completing missions!',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
