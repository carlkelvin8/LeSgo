import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';

class HeroBanner extends StatelessWidget {
  final String userName;
  final String backgroundImagePath;
  final VoidCallback? onBookNowPressed;

  const HeroBanner({
    super.key,
    required this.userName,
    required this.backgroundImagePath,
    this.onBookNowPressed,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.spacing(context, 16.0);
    final bannerHeight = ResponsiveUtils.imageHeight(context, 220);
    final borderRadius = ResponsiveUtils.spacing(context, 16);
    final fontSize22 = ResponsiveUtils.fontSize(context, 22);
    final fontSize12 = ResponsiveUtils.fontSize(context, 12);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          height: bannerHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(backgroundImagePath, fit: BoxFit.cover),
              ),

              Positioned(
                left: ResponsiveUtils.spacing(context, 20),
                top: 0,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hello, $userName!',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: fontSize22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      'Ready to Order?',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.black,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.spacing(context, 8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: const Color(
                              0xFFA930D0,
                            ).withValues(alpha: 0.4),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: onBookNowPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA930D0),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.spacing(context, 24),
                            vertical: ResponsiveUtils.spacing(context, 12),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.spacing(context, 8),
                            ),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          'BOOK NOW',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
