import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';

class LespayMenuItem extends StatelessWidget {
  final String iconPath;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool useColorFilter;
  final bool addStroke;

  const LespayMenuItem({
    super.key,
    required this.iconPath,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.useColorFilter = true,
    this.addStroke = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 16),
          vertical: ResponsiveUtils.spacing(context, 16),
        ),
        child: Row(
          children: [
            Container(
              width: ResponsiveUtils.spacing(context, 40),
              height: ResponsiveUtils.spacing(context, 40),
              decoration: BoxDecoration(
                color: backgroundColor ?? const Color(0xFF5F2D82),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: addStroke
                    ? Stack(
                        children: [
                          // Black stroke/outline
                          SvgPicture.asset(
                            iconPath,
                            width: ResponsiveUtils.fontSize(context, 24),
                            height: ResponsiveUtils.fontSize(context, 24),
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          // Original SVG on top
                          Positioned(
                            top: 0.5,
                            left: 0.5,
                            child: SvgPicture.asset(
                              iconPath,
                              width: ResponsiveUtils.fontSize(context, 24) - 1,
                              height: ResponsiveUtils.fontSize(context, 24) - 1,
                              colorFilter: useColorFilter
                                  ? ColorFilter.mode(
                                      iconColor ?? Colors.white,
                                      BlendMode.srcIn,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      )
                    : SvgPicture.asset(
                        iconPath,
                        width: ResponsiveUtils.fontSize(context, 24),
                        height: ResponsiveUtils.fontSize(context, 24),
                        colorFilter: useColorFilter
                            ? ColorFilter.mode(
                                iconColor ?? Colors.white,
                                BlendMode.srcIn,
                              )
                            : null,
                      ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: ResponsiveUtils.fontSize(context, 16),
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
