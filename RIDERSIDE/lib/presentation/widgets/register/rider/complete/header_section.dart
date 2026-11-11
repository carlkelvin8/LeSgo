import 'package:flutter/material.dart';
import '../../../../../../core/utils/utils.dart';
import '../../../../../core/utils/dark_aware_colors.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: ResponsiveUtils.spacing(context, 40)),
        Text(
          'CONGRATULATIONS!',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 28),
            fontWeight: FontWeight.w900,
            color: context.txt(Colors.black87),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 4)),
        Text(
          'You have successfully created your account',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            fontWeight: FontWeight.w400,
            color: context.sub(Colors.black54),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
