import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/utils/responsive_utils.dart';

class LeseatBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const LeseatBanner({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = ResponsiveUtils.spacing(context, 16);
    final bannerHeight = ResponsiveUtils.imageHeight(context, 120);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: bannerHeight,
        width: double.infinity,
        margin: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 16),
          vertical: ResponsiveUtils.spacing(context, 16),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SvgPicture.asset(
            'assets/images/book/leseat/Banner.svg',
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
      ),
    );
  }
}
