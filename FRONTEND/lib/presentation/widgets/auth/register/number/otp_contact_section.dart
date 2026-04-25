import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive_utils.dart';
import '../../../widgets.dart';

class OtpContactSection extends StatelessWidget {
  const OtpContactSection({
    super.key,
    required this.phoneController,
    required this.onResend,
    this.otpSent = false,
  });

  final TextEditingController phoneController;
  final VoidCallback onResend;
  final bool otpSent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Contact number',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        PhoneNumberField(
          controller: phoneController,
          focusedBorderColor: const Color(0xFF5F2D82),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        if (otpSent)
          GestureDetector(
            onTap: onResend,
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: Colors.black54,
                ),
                children: [
                  const TextSpan(text: "Didn't receive code? "),
                  TextSpan(
                    text: 'Resend OTP',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(height: ResponsiveUtils.spacing(context, 24)),
      ],
    );
  }
}
