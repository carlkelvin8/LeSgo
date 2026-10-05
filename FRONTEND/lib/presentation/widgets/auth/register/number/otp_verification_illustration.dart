import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/utils/responsive_utils.dart';

class OtpVerificationIllustration extends StatelessWidget {
  const OtpVerificationIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/images/register/8.svg',
          width: ResponsiveUtils.imageHeight(context, 240),
          height: ResponsiveUtils.imageHeight(context, 240),
          fit: BoxFit.contain,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 24)),
      ],
    );
  }
}

