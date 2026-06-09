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
    
    final editIconSize = ResponsiveUtils.fontSize(context, 14);

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onMenuTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(top: ResponsiveUtils.spacing(context, 12)),
              child: SvgPicture.asset(
                'assets/images/homepage/Nav.svg',
                width: iconSize,
                height: iconSize,
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: GestureDetector(
              onTap: onLocationTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.only(top: ResponsiveUtils.spacing(context, 6)),
                child: Column(
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
                    SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: fontSize14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                        SvgPicture.asset(
                          'assets/images/homepage/Edit.svg',
                          width: editIconSize,
                          height: editIconSize,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
