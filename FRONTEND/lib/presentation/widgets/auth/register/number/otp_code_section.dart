import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive_utils.dart';
import '../../../widgets.dart';
import '../../../../provider/register/controller/otp_verification.controller.notifier.dart';

class OtpCodeSection extends StatelessWidget {
  const OtpCodeSection({
    super.key,
    required this.controllers,
  });

  final OtpVerificationControllers controllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verification Code',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Text(
          'We have sent a verification code to your phone number',
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 12),
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        OtpInputFields(
          controllers: controllers.otpControllers,
          focusedBorderColor: const Color(0xFF7C3AED),
        ),
      ],
    );
  }
}

