import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';

class VerificationCodeSection extends StatelessWidget {
  final String? devOtp;

  const VerificationCodeSection({super.key, this.devOtp});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Code',
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Text(
          'we have sent a verification code to your phone number',
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 14),
            color: Colors.black54,
          ),
        ),
        // Show OTP in dev/fallback mode
        if (devOtp != null) ...[
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.spacing(context, 12),
              vertical: ResponsiveUtils.spacing(context, 8),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700)),
            ),
            child: Row(
              children: [
                const Icon(Icons.developer_mode, size: 16, color: Color(0xFF856404)),
                SizedBox(width: ResponsiveUtils.spacing(context, 6)),
                Text(
                  'Dev OTP: $devOtp',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF856404),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
