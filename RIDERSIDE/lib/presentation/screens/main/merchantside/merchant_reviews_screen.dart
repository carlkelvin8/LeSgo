import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/screen_auto_refresh.dart';
import '../../../../data/data_source/dto/merchant/review_dto.dart';
import '../../../mixins/auto_refresh_mixin.dart';
import '../../../provider/main/merchantside/merchant_reviews_provider.dart';
import '../../../widgets/common/settings_page_kit.dart';
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
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SettingsKit.appBar(context, ''),
      body: reviewsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: SettingsKit.brand),
        ),
        error: (error, _) => Center(
          child: SettingsEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Failed to load reviews',
            subtitle: '$error',
            actionLabel: 'Retry',
            actionIcon: Icons.refresh_rounded,
            onAction: () =>
                ref.read(merchantReviewsNotifierProvider.notifier).load(),
          ),
        ),
        data: (dashboard) {
          final filtered = _filteredReviews(dashboard.reviews, starFilter);

          return RefreshIndicator(
            color: SettingsKit.brand,
            onRefresh: () =>
                ref.read(merchantReviewsNotifierProvider.notifier).load(),
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(hp, 0, hp, 32),
              children: [
                const SettingsPageHeader(
                  title: 'Customer Reviews',
                  subtitle: 'See what customers say about your store',
                ),
                const SizedBox(height: 20),
                _buildSummaryCard(context, dashboard.statistics),
                const SizedBox(height: 20),
                _buildFilterRow(context, starFilter, dashboard.statistics),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SettingsEmptyState(
                      icon: Icons.reviews_outlined,
                      title: starFilter == null
                          ? 'No reviews yet'
                          : 'No $starFilter-star reviews',
                      subtitle: starFilter == null
                          ? 'Reviews from customers will appear here after they rate their orders.'
                          : 'Try a different rating filter.',
                    ),
                  )
                else
                  ...filtered.map(
                    (review) => MerchantReviewCard(review: review),
                  ),
                if (dashboard.hasMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SettingsKit.brand,
                      ),
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
    final total = stats.totalReviews;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            SettingsKit.brandLight,
            SettingsKit.brand,
            Color(0xFF3E1460),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: SettingsKit.brand.withValues(alpha: .25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Average rating
          SizedBox(
            width: 104,
            child: Column(
              children: [
                Text(
                  stats.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final fill = (stats.averageRating - i).clamp(0.0, 1.0);
                    return Icon(
                      fill >= .75
                          ? Icons.star_rounded
                          : fill >= .25
                          ? Icons.star_half_rounded
                          : Icons.star_outline_rounded,
                      size: 17,
                      color: const Color(0xFFFFC94D),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  '$total ${total == 1 ? 'review' : 'reviews'}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: .8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 112,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: Colors.white.withValues(alpha: .18),
          ),
          // Distribution
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final stars = 5 - index;
                final count = stats.ratingDistribution['$stars'] ?? 0;
                final progress = total == 0 ? 0.0 : count / total;
                return Padding(
                  padding: EdgeInsets.only(bottom: index == 4 ? 0 : 7),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        child: Text(
                          '$stars',
                          style: const TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFFFC94D),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: Colors.white.withValues(
                              alpha: .16,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFFFFC94D),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: .85),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
    BuildContext context,
    int? selected,
    ReviewStatisticsDto stats,
  ) {
    final filters = <int?>[null, 5, 4, 3, 2, 1];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = filters[i];
          final isSelected = selected == filter;
          final count = filter == null
              ? stats.totalReviews
              : stats.ratingDistribution['$filter'] ?? 0;
          final fg = isSelected ? Colors.white : SettingsKit.ink;

          return GestureDetector(
            onTap: () =>
                ref.read(merchantReviewFilterProvider.notifier).state = filter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? SettingsKit.brand : SettingsKit.pageBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filter != null) ...[
                    Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: isSelected
                          ? const Color(0xFFFFC94D)
                          : const Color(0xFFF5A623),
                    ),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    filter == null ? 'All' : '$filter',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white.withValues(alpha: .75)
                          : SettingsKit.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
