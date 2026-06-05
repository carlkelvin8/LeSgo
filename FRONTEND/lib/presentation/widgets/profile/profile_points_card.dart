import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';

class ProfilePointsCard extends StatelessWidget {
  final int points;
  final VoidCallback? onTap;

  const ProfilePointsCard({
    super.key,
    required this.points,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My points:',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        GestureDetector(
          onTap: onTap,
          child: Container(
          width: double.infinity,
          height: ResponsiveUtils.spacing(context, 158),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF7B3FF2),
                Color(0xFFB565D8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned(
                top: ResponsiveUtils.spacing(context, 10),
                left: 0,
                right: 0,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/mission/Star.svg',
                    width: ResponsiveUtils.spacing(context, 100),
                    height: ResponsiveUtils.spacing(context, 100),
                  ),
                ),
              ),
              Positioned(
                bottom: ResponsiveUtils.spacing(context, 15),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '$points POINTS',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 24),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
        if (onTap != null) ...[
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            'Tap to redeem points',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 11),
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
