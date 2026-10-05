import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/screen_auto_refresh.dart';
import '../../../../data/data_source/dto/merchant/review_dto.dart';
import '../../../mixins/auto_refresh_mixin.dart';
import '../../../provider/main/merchantside/merchant_reviews_provider.dart';
import '../../../widgets/main/merchantside/reviews/merchant_rating_distribution_chart.dart';
import '../../../widgets/main/merchantside/reviews/merchant_rating_stars_display.dart';
import '../../../widgets/main/merchantside/reviews/merchant_review_card.dart';

final merchantReviewFilterProvider = StateProvider<int?>((ref) => null);

class MerchantReviewsScreen extends ConsumerStatefulWidget {
  const MerchantReviewsScreen({super.key});

  @override
  ConsumerState<MerchantReviewsScreen> createState() =>
      _MerchantReviewsScreenState();
}

class _MerchantReviewsScreenState extends ConsumerState<MerchantReviewsScreen>
    with WidgetsBindingObserver, AutoRefreshMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  Duration get autoRefreshInterval => kScreenAutoRefreshInterval;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void onAutoRefresh() {
    ref.read(merchantReviewsNotifierProvider.notifier).load();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(merchantReviewsNotifierProvider.notifier).loadMore();
    }
  }

  List<ReviewDto> _filteredReviews(List<ReviewDto> reviews, int? starFilter) {
    if (starFilter == null) return reviews;
    return reviews.where((review) => review.rating == starFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(merchantReviewsNotifierProvider);
    final starFilter = ref.watch(merchantReviewFilterProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Customer Reviews',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load reviews',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(merchantReviewsNotifierProvider.notifier).load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (dashboard) {
          final filtered = _filteredReviews(dashboard.reviews, starFilter);

          return RefreshIndicator(
            color: const Color(0xFF5F2D82),
            onRefresh: () =>
                ref.read(merchantReviewsNotifierProvider.notifier).load(),
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                ResponsiveUtils.spacing(context, 16),
                horizontalPadding,
                ResponsiveUtils.spacing(context, 24),
              ),
              children: [
                _buildSummaryCard(context, dashboard.statistics),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                _buildFilterRow(context, starFilter),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                if (filtered.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveUtils.spacing(context, 40),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          starFilter == null
                              ? 'No reviews yet'
                              : 'No $starFilter-star reviews yet',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 16),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.map(
                    (review) => MerchantReviewCard(review: review),
                  ),
                if (dashboard.hasMore)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveUtils.spacing(context, 12),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, ReviewStatisticsDto stats) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D9F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stats.averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 42),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF5F2D82),
                  height: 1,
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MerchantRatingStarsDisplay(
                      rating: stats.averageRating,
                      size: ResponsiveUtils.fontSize(context, 18),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                    Text(
                      '${stats.totalReviews} ${stats.totalReviews == 1 ? 'review' : 'reviews'}',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 13),
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 18)),
          MerchantRatingDistributionChart(
            distribution: stats.ratingDistribution,
            totalReviews: stats.totalReviews,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, int? selected) {
    final filters = <int?>[null, 5, 4, 3, 2, 1];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selected == filter;
          final label = filter == null ? 'All' : '$filter★';

          return Padding(
            padding: EdgeInsets.only(
              right: ResponsiveUtils.spacing(context, 8),
            ),
            child: FilterChip(
              label: Text(
                label,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                ref.read(merchantReviewFilterProvider.notifier).state = filter;
              },
              selectedColor: const Color(0xFFE8D9F5),
              checkmarkColor: const Color(0xFF5F2D82),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF5F2D82)
                    : Colors.grey.shade300,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
