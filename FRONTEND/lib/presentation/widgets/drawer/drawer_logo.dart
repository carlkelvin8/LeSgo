import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';

class DrawerLogo extends StatelessWidget {
  const DrawerLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 24),
        vertical: ResponsiveUtils.spacing(context, 32),
      ),
      child: SvgPicture.asset(
        'assets/images/Logo.svg',
        height: ResponsiveUtils.imageHeight(context, 60),
        fit: BoxFit.contain,
        colorFilter: const ColorFilter.mode(
          Colors.white,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
