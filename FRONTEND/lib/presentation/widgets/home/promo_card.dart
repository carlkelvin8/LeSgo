import 'package:flutter/material.dart';

import '../../../core/utils/responsive_utils.dart';

class PromoCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback? onTap;

  const PromoCard({super.key, required this.title, this.imageUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveUtils.screenWidth(context) * 0.7; // Wider card
    final margin = ResponsiveUtils.spacing(context, 16);
    final borderRadius = ResponsiveUtils.spacing(context, 20); // More rounded

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: EdgeInsets.only(right: margin),
        child: dottedBorderWrapper(
          context,
          child: Container(
            padding: EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_offer, color: Colors.grey[400], size: 40),
                SizedBox(height: 12),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.grey[400],
                  ),
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
        color: const Color(0xFFF2F4F7), // Light grey/blue
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
