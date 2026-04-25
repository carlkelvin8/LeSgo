import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';

class LocationHeader extends StatelessWidget {
  final String location;
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLocationTap;

  const LocationHeader({
    super.key,
    required this.location,
    this.onMenuTap,
    this.onProfileTap,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveUtils.spacing(context, 16.0);
    final fontSize12 = ResponsiveUtils.fontSize(context, 12);
    final fontSize14 = ResponsiveUtils.fontSize(context, 14);
    final iconSize = ResponsiveUtils.fontSize(context, 24);
    
    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onMenuTap,
                child: SvgPicture.asset(
                  'assets/images/homepage/Nav.svg',
                  width: iconSize,
                  height: iconSize,
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              GestureDetector(
                onTap: onLocationTap,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/homepage/Location.svg',
                              width: ResponsiveUtils.fontSize(context, 14),
                              height: ResponsiveUtils.fontSize(context, 14),
                            ),
                            SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                            Text(
                              'Current Location',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: fontSize12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              location,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: fontSize14,
                                color: Colors.black87
                              ),
                            ),
                            SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                            SvgPicture.asset(
                              'assets/images/homepage/Edit.svg',
                              width: ResponsiveUtils.fontSize(context, 12),
                              height: ResponsiveUtils.fontSize(context, 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onProfileTap,
            child: SvgPicture.asset(
              'assets/images/homepage/Profile.svg',
              width: ResponsiveUtils.spacing(context, 32),
              height: ResponsiveUtils.spacing(context, 32),
            ),
          ),
        ],
      ),
    );
  }
}
