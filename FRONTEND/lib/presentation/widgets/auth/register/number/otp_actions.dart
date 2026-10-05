import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive_utils.dart';
import '../../../widgets.dart';

class OtpActions extends StatelessWidget {
  const OtpActions({
    super.key,
    required this.isLoading,
    required this.onContinue,
    this.text = 'Next',
  });

  final bool isLoading;
  final VoidCallback onContinue;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        PrimaryButton(
          text: text,
          onPressed: isLoading ? null : onContinue,
          backgroundColor: const Color(0xFF5F2D82),
          isLoading: isLoading,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
      ],
    );
  }
}
