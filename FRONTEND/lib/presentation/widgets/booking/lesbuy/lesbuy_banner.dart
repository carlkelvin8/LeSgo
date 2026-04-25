import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';

class LesbuyBanner extends StatelessWidget {
  const LesbuyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 8),
      ),
      height: ResponsiveUtils.imageHeight(context, 120),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5F2D82), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.spacing(context, 16),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: ResponsiveUtils.spacing(context, 16),
            top: 0,
            bottom: 0,
            child: Icon(
              Icons.shopping_bag,
              size: ResponsiveUtils.fontSize(context, 80),
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Shop Anything!',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 20),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  'Medicine, school supplies, hardware & more',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
