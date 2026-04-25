import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';
import 'phone_input_field.dart';
import 'send_otp_button.dart';
import 'resend_otp_button.dart';
import 'verification_code_section.dart';
import 'otp_input_boxes.dart';
import 'section_label.dart';

/// Groups the phone input, OTP send/resend, and OTP input boxes
/// into a single widget.
class PhoneVerificationForm extends StatelessWidget {
  final TextEditingController phoneController;
  final List<TextEditingController> otpControllers;
  final bool otpSent;
  final bool isLoading;
  final bool isPhoneNumberValid;
  final VoidCallback onSendOTP;
  final VoidCallback onResendOTP;

  const PhoneVerificationForm({
    super.key,
    required this.phoneController,
    required this.otpControllers,
    required this.otpSent,
    required this.isLoading,
    required this.isPhoneNumberValid,
    required this.onSendOTP,
    required this.onResendOTP,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SectionLabel(text: 'Contact number'),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        PhoneInputField(controller: phoneController),

        if (!otpSent) ...[
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          SendOTPButton(
            isLoading: isLoading,
            isEnabled: isPhoneNumberValid,
            onPressed: onSendOTP,
          ),
        ],

        if (otpSent) ...[
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          ResendOTPButton(onPressed: onResendOTP),
          SizedBox(height: ResponsiveUtils.spacing(context, 32)),
          const VerificationCodeSection(),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          OTPInputBoxes(controllers: otpControllers),
          SizedBox(height: ResponsiveUtils.spacing(context, 40)),
        ],
      ],
    );
  }
}
