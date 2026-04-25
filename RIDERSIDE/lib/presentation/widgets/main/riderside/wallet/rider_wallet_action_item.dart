import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class RiderWalletActionItem extends StatelessWidget {
  final String iconAsset;
  final String title;

  const RiderWalletActionItem({
    super.key,
    required this.iconAsset,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 24)),
      child: Row(
        children: [
          SvgPicture.asset(
            iconAsset,
            width: ResponsiveUtils.imageHeight(context, 48),
            height: ResponsiveUtils.imageHeight(context, 48),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 16)),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                fontWeight: FontWeight.w400,
                color: const Color(0xFF5F2D82), // Purple text
              ),
            ),
          ),
        ],
      ),
    );
  }
}
