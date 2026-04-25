import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';

class LocationHeaderSection extends StatelessWidget {
  final String userName;
  final String address;

  const LocationHeaderSection({
    super.key,
    required this.userName,
    required this.address,
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
            userName,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
          Text(
            address,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
