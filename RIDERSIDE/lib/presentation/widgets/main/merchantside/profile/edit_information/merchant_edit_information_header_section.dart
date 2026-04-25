import 'package:flutter/material.dart';
import '../../../../../../../core/utils/responsive_utils.dart';

class MerchantEditInformationHeaderSection extends StatelessWidget {
  const MerchantEditInformationHeaderSection({
    super.key,
    required this.restaurantName,
    required this.onCameraTap,
  });

  final String restaurantName;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _MerchantLogoBadge(onCameraTap: onCameraTap),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        Text(
          restaurantName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 22),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4D1E6D),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 2)),
      ],
    );
  }
}

class _MerchantLogoBadge extends StatelessWidget {
  const _MerchantLogoBadge({required this.onCameraTap});

  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ResponsiveUtils.spacing(context, 128),
      height: ResponsiveUtils.spacing(context, 128),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: ResponsiveUtils.spacing(context, 128),
            height: ResponsiveUtils.spacing(context, 128),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFCB63), Color(0xFFF4A400)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SUN SETS PIZZA',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 7.5),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    '0.',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 30),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 0.9,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: ResponsiveUtils.spacing(context, -2),
            bottom: ResponsiveUtils.spacing(context, 8),
            child: GestureDetector(
              onTap: onCameraTap,
              child: Container(
                width: ResponsiveUtils.spacing(context, 34),
                height: ResponsiveUtils.spacing(context, 34),
                decoration: const BoxDecoration(
                  color: Color(0xFF5A1D8D),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.white,
                  size: ResponsiveUtils.spacing(context, 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}