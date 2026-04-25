import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MerchantFoodDetailHeader extends StatelessWidget {
  final VoidCallback onBack;

  const MerchantFoodDetailHeader({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveUtils.spacing(context, 12),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          GestureDetector(
            onTap: onBack,
            child: Icon(
              Icons.chevron_left_rounded,
              size: ResponsiveUtils.imageHeight(context, 32),
              color: const Color(0xFF5F2D82),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/images/Logo.svg',
              height: ResponsiveUtils.imageHeight(context, 28),
              colorFilter: const ColorFilter.mode(
                Color(0xFF5F2D82),
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.imageHeight(context, 32)),
        ],
      ),
    );
  }
}
