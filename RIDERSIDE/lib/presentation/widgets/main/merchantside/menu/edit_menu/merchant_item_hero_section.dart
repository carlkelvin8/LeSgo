import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

/// Hero section for edit item screen with gradient background and pizza icon
class MerchantItemHeroSection extends StatelessWidget {
  const MerchantItemHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: ResponsiveUtils.spacing(context, 160),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE5CC),
            Color(0xFFFFD4A3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_pizza_rounded,
                size: ResponsiveUtils.fontSize(context, 64),
                color: const Color(0xFFFFA500),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Text(
                'CURRENTLY EDITING',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 11),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B4513),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.camera_alt,
                size: ResponsiveUtils.fontSize(context, 20),
                color: const Color(0xFF5F2D82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
