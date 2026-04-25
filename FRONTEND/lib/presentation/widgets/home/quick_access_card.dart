import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';

class QuickAccessCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const QuickAccessCard({
    super.key,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive sizes
    final iconSize = ResponsiveUtils.fontSize(
      context,
      36,
    ); // Smaller icon inside circle
    final titleSize = ResponsiveUtils.fontSize(context, 16);
    final subtitleSize = ResponsiveUtils.fontSize(context, 10);
    final cardPadding = ResponsiveUtils.spacing(context, 16);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: ResponsiveUtils.imageHeight(
            context,
            160,
          ), // Fixed height for square-ish look
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Arrow Icon (Top Right)
              Positioned(
                top: 0,
                right: 0,
                child: SvgPicture.asset(
                  'assets/images/homepage/Arrow.svg',
                  width: ResponsiveUtils.fontSize(context, 12),
                  height: ResponsiveUtils.fontSize(context, 12),
                  colorFilter: ColorFilter.mode(
                    Colors.grey[400]!,
                    BlendMode.srcIn,
                  ),
                ),
              ),

              // Main Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon in Circle
                  Container(
                    width: ResponsiveUtils.fontSize(context, 60),
                    height: ResponsiveUtils.fontSize(context, 60),
                    padding: EdgeInsets.all(
                      ResponsiveUtils.spacing(context, 12),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEDDFD), // Light purple background
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      iconPath,
                      width: iconSize,
                      height: iconSize,
                    ),
                  ),

                  const Spacer(),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),

                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: subtitleSize,
                      color: Colors.grey[500],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
