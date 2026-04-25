import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/utils/responsive_utils.dart';

class LestransportCoverageMap extends StatelessWidget {
  final String imagePath;

  const LestransportCoverageMap({
    super.key,
    this.imagePath = 'assets/images/book/lestransport_map.png',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Area coverage of LesTransport',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Container(
            width: double.infinity,
            height: ResponsiveUtils.imageHeight(context, 120),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SvgPicture.asset(
                'assets/images/book/letstransport/letstransport_map.svg',
                fit: BoxFit.cover,
                placeholderBuilder: (context) => Center(
                  child: Icon(
                    Icons.map,
                    size: ResponsiveUtils.fontSize(context, 48),
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
