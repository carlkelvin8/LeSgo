import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';

class ResendOTPButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ResendOTPButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: TextButton(
        onPressed: onPressed,
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.black54,
            ),
            children: [
              const TextSpan(
                text: "Didn't receive code? ",
              ),
              TextSpan(
                text: 'Resend OTP',
                style: TextStyle(
                  color: const Color(0xFF5F2D82),
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
