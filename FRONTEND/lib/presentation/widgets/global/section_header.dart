import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAllPressed;

  const SectionHeader({super.key, required this.title, this.onSeeAllPressed});

  @override
  Widget build(BuildContext context) {
    // Remove Padding from here because usually it's handled by parent or we want strictly between edges
    // Actually existing implementation had Padding horizontal 16. The new usage has external padding.
    // I'll keep it flexible but maybe remove internal padding to be more reusable if I wrap it in padding externally.
    // Given the previous usage, let's keep it safe but turn it into a Row.

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(
                context,
                18,
              ), // Increased size for bold header
              fontWeight: FontWeight.bold,
              color: Colors
                  .black, // Darker color as per image (Offers for You is bold black/dark grey)
            ),
          ),
          if (onSeeAllPressed != null)
            GestureDetector(
              onTap: onSeeAllPressed,
              child: Text(
                'See All',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFA930D0), // Purple color
                ),
              ),
            ),
        ],
      ),
    );
  }
}
