import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/utils/responsive_utils.dart';

class AvatarIconContainer extends StatelessWidget {
  final String? svgAsset;
  final IconData? icon;
  final double size;
  final Color backgroundColor;
  final double iconSize;

  const AvatarIconContainer({
    super.key,
    this.svgAsset,
    this.icon,
    this.size = 60,
    this.backgroundColor = const Color(0xFFE9D7FE),
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveSize = ResponsiveUtils.spacing(context, size);
    final responsiveIconSize = ResponsiveUtils.spacing(context, iconSize);
    return Container(
      width: responsiveSize,
      height: responsiveSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: svgAsset != null
            ? SvgPicture.asset(
                svgAsset!,
                width: responsiveIconSize,
                height: responsiveIconSize,
                fit: BoxFit.contain,
              )
            : icon != null
                ? Icon(
                    icon,
                    size: responsiveIconSize,
                    color: Colors.white,
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
