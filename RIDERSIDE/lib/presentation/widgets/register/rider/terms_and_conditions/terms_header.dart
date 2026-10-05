import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';

class TermsHeader extends StatelessWidget {
  const TermsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Terms and Conditions',
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 20),
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }
}
