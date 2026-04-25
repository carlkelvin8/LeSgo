import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';

class SubmitInfoText extends StatelessWidget {
  const SubmitInfoText({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'We appreciate your application and are excited to welcome you aboard!\n\n'
      'Please allow us 24 to 48 hours to carefully review your details. Upon successful approval, you\'ll be fully onboarded, set up with your free delivery gear valued at PHP 2,000. This fee includes your uniform, bag, and a helmet, ensuring you\'re ready to start delivering promptly and professionalism.\n\n'
      'Once your registration is complete, you can begin delivering packages immediately!',
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 11),
        fontWeight: FontWeight.w400,
        color: Colors.black54,
        height: 1.4,
      ),
    );
  }
}
