import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../core/utils/utils.dart';

class MerchantCompleteIllustration extends StatelessWidget {
  const MerchantCompleteIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: ResponsiveUtils.spacing(context, 40)),
        SvgPicture.asset(
          'assets/images/register/9.svg',
          height: ResponsiveUtils.imageHeight(context, 340),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 40)),
      ],
    );
  }
}
