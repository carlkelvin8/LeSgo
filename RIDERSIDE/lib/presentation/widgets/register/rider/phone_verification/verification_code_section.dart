import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';

class VerificationCodeSection extends StatelessWidget {
  const VerificationCodeSection({super.key});

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
      ],
    );
  }
}
