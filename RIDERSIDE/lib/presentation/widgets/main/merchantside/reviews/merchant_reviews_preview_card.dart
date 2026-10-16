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

    return Material(
      color: const Color(0xFFF5F4F7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => AppRouter.push(context, MainRoutes.merchantReviews),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 7)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.star,
                      color: const Color(0xFFFFB300),
                      size: ResponsiveUtils.fontSize(context, 17),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.north_east_rounded,
                    size: 14,
                    color: Color(0xFFA49BAE),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              Text(
                'Customer Reviews',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF302B36),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 6)),
              Row(
                children: [
                  MerchantRatingStarsDisplay(
                    rating: rating,
                    size: ResponsiveUtils.fontSize(context, 13),
                    showRatingText: true,
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 6)),
                  Text(
                    '($total)',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 11),
                      color: const Color(0xFF918A98),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
