import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/utils/utils.dart';

class InfoIllustration extends StatelessWidget {
  const InfoIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SvgPicture.asset(
        'assets/images/register/7.svg',
        height: ResponsiveUtils.imageHeight(context, 240),
        fit: BoxFit.contain,
      ),
    );
  }
}
