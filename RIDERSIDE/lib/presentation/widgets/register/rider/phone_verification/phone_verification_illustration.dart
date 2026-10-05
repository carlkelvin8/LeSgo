import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/utils/utils.dart';

class PhoneVerificationIllustration extends StatelessWidget {
  const PhoneVerificationIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/register/8.svg',
      height: ResponsiveUtils.imageHeight(context, 240),
      fit: BoxFit.contain,
    );
  }
}
