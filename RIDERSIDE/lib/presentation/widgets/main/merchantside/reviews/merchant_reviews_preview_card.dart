import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_profile_provider.dart';
import '../../../../provider/main/merchantside/merchant_reviews_provider.dart';
import 'merchant_rating_stars_display.dart';

class MerchantReviewsPreviewCard extends ConsumerWidget {
  const MerchantReviewsPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(merchantProfileProvider);
    final reviewsAsync = ref.watch(merchantReviewsDashboardProvider);

    final profileRating = profileAsync.valueOrNull?.rating ?? 0;
    final profileTotal = profileAsync.valueOrNull?.totalReviews ?? 0;

    final rating = reviewsAsync.maybeWhen(
      data: (dashboard) => dashboard.statistics.averageRating,
      orElse: () => profileRating,
    );
    final total = reviewsAsync.maybeWhen(
      data: (dashboard) => dashboard.statistics.totalReviews,
      orElse: () => profileTotal,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.spacing(context, 44),
            height: ResponsiveUtils.spacing(context, 44),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA000),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: ResponsiveUtils.fontSize(context, 24),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Reviews',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 15),
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Row(
                  children: [
                    MerchantRatingStarsDisplay(
                      rating: rating,
                      size: ResponsiveUtils.fontSize(context, 14),
                      showRatingText: true,
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                    Text(
                      '($total)',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              AppRouter.push(context, MainRoutes.merchantReviews);
            },
            child: Text(
              'View',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5F2D82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
