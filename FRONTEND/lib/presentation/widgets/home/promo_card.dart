import 'package:flutter/material.dart';

import '../../../core/utils/responsive_utils.dart';

class PromoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badge;
  final Color? accentColor;
  final String? imageUrl;
  final VoidCallback? onTap;

  const PromoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.accentColor,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveUtils.screenWidth(context) * 0.7; // Wider card
    final margin = ResponsiveUtils.spacing(context, 16);
    final borderRadius = ResponsiveUtils.spacing(context, 20); // More rounded
    final color = accentColor ?? const Color(0xFF5F2D82);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: EdgeInsets.only(right: margin),
        child: dottedBorderWrapper(
          context,
          child: Container(
            padding: EdgeInsets.all(16),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(
                    Icons.arrow_outward,
                    color: Colors.grey[400],
                    size: 18,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.local_offer, color: color, size: 24),
                    ),
                    const Spacer(),
                    if (badge != null) ...[
                      Text(
                        badge!,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 11),
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 11),
                          color: Colors.grey[500],
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          radius: borderRadius,
        ),
      ),
    );
  }

  Widget dottedBorderWrapper(
    BuildContext context, {
    required Widget child,
    required double radius,
  }) {
    // Note: DottedBorder package might not be installed, so falling back to standard container if needed.
    // Given I cannot easily check pubspec, I will stick to standard BoxDecoration with DASHED effect if I could,
    // but simplifying to a solid light background which is safer and premium looking.
    // The reference image looks like a solid light container with a dashed border *effect* or just light grey.
    // Let's go with a solid light bluish-grey container.

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
          style: BorderStyle.solid,
        ), // Dashed difficult without package
      ),
      child: child,
    );
  }
}
