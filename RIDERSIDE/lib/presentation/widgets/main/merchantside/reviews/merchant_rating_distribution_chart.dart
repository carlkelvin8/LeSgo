import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class MerchantRatingDistributionChart extends StatelessWidget {
  final Map<String, int> distribution;
  final int totalReviews;

  const MerchantRatingDistributionChart({
    super.key,
    required this.distribution,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        final stars = 5 - index;
        final count = distribution['$stars'] ?? 0;
        final progress = totalReviews == 0 ? 0.0 : count / totalReviews;

        return Padding(
          padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 6)),
          child: Row(
            children: [
              SizedBox(
                width: ResponsiveUtils.spacing(context, 28),
                child: Text(
                  '$stars★',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: ResponsiveUtils.spacing(context, 8),
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFFFFA000),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 8)),
              SizedBox(
                width: ResponsiveUtils.spacing(context, 24),
                child: Text(
                  '$count',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
