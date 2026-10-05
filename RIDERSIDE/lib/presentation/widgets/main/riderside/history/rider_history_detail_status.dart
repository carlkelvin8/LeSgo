import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class RiderHistoryDetailStatus extends StatelessWidget {
  final int rating;
  final String status;
  final Color statusColor;
  final Color statusBackgroundColor;

  const RiderHistoryDetailStatus({
    super.key,
    required this.rating,
    required this.status,
    required this.statusColor,
    required this.statusBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Restaurant Image Placeholder
        Container(
          width: ResponsiveUtils.spacing(context, 120),
          height: ResponsiveUtils.spacing(context, 120),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.spacing(context, 16),
            ),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.restaurant,
            size: ResponsiveUtils.imageHeight(context, 60),
            color: Colors.grey.shade400,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        // Stars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            rating,
            (index) => Icon(
              Icons.star_rounded,
              size: ResponsiveUtils.fontSize(context, 24),
              color: const Color(0xFFFFC107),
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),

        // Status Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spacing(context, 16),
            vertical: ResponsiveUtils.spacing(context, 6),
          ),
          decoration: BoxDecoration(
            color: statusBackgroundColor,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.spacing(context, 20),
            ),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
