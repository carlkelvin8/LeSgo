import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';

class DrawerMenuItem extends StatelessWidget {
  final String? iconPath;
  /// Material icon used instead of [iconPath] when there is no SVG asset.
  final IconData? icon;
  final String title;
  final VoidCallback onTap;

  const DrawerMenuItem({
    super.key,
    this.iconPath,
    this.icon,
    required this.title,
    required this.onTap,
  }) : assert(iconPath != null || icon != null);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 24),
          vertical: ResponsiveUtils.spacing(context, 16),
        ),
        child: Row(
          children: [
            if (icon != null)
              Icon(
                icon,
                color: Colors.white,
                size: ResponsiveUtils.fontSize(context, 24),
              )
            else
              SvgPicture.asset(
                iconPath!,
                width: ResponsiveUtils.fontSize(context, 24),
                height: ResponsiveUtils.fontSize(context, 24),
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            SizedBox(width: ResponsiveUtils.spacing(context, 16)),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.fontSize(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
