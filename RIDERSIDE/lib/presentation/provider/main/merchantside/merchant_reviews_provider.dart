import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/dto/merchant/review_dto.dart';
import '../../auth/rider_auth_provider.dart';
import 'merchant_profile_provider.dart';

class MerchantReviewsDashboard {
  final ReviewStatisticsDto statistics;
  final List<ReviewDto> reviews;
  final bool hasMore;
  final int nextPage;

  const MerchantReviewsDashboard({
    required this.statistics,
    required this.reviews,
    this.hasMore = false,
    this.nextPage = 2,
  });

  MerchantReviewsDashboard copyWith({
    ReviewStatisticsDto? statistics,
    List<ReviewDto>? reviews,
    bool? hasMore,
    int? nextPage,
  }) {
    return MerchantReviewsDashboard(
      statistics: statistics ?? this.statistics,
      reviews: reviews ?? this.reviews,
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? this.nextPage,
    );
  }
}

final merchantReviewsDashboardProvider =
    FutureProvider.autoDispose<MerchantReviewsDashboard>((ref) async {
  final authState = ref.watch(riderAuthProvider);
  final partnerId = authState.user?.partnerId;
  if (partnerId == null) {
    throw Exception('Partner ID not found');
  }

  final dataSource = ref.read(merchantDataSourceProvider);
  final profile = await ref.watch(merchantProfileProvider.future);

  final page = await dataSource.getPartnerReviews(partnerId);
  final apiStats = await dataSource.getPartnerReviewStatistics(partnerId);

  var statistics = apiStats ??
      ReviewStatisticsDto.fromReviews(
        page.reviews,
        fallbackAverage: profile?.rating,
        fallbackTotal: profile?.totalReviews,
      );

  if (statistics.ratingDistribution.isEmpty && page.reviews.isNotEmpty) {
    statistics = ReviewStatisticsDto.fromReviews(
      page.reviews,
      fallbackAverage: statistics.averageRating > 0
          ? statistics.averageRating
          : profile?.rating,
      fallbackTotal: statistics.totalReviews > 0
          ? statistics.totalReviews
          : profile?.totalReviews,
    );
  }

  return MerchantReviewsDashboard(
    statistics: statistics,
    reviews: page.reviews,
    hasMore: page.hasMore,
    nextPage: page.currentPage + 1,
  );
});

class MerchantReviewsNotifier extends StateNotifier<AsyncValue<MerchantReviewsDashboard>> {
  final Ref _ref;

  MerchantReviewsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _ref.read(merchantReviewsDashboardProvider.future);
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || state.isLoading) return;

    final partnerId = _ref.read(riderAuthProvider).user?.partnerId;
    if (partnerId == null) return;

    try {
      final dataSource = _ref.read(merchantDataSourceProvider);
      final page = await dataSource.getPartnerReviews(
        partnerId,
        page: current.nextPage,
      );

      state = AsyncValue.data(
        current.copyWith(
          reviews: [...current.reviews, ...page.reviews],
          hasMore: page.hasMore,
          nextPage: page.currentPage + 1,
        ),
      );
    } catch (_) {
      // Keep existing reviews visible if pagination fails.
    }
  }
}

final merchantReviewsNotifierProvider = StateNotifierProvider.autoDispose<
    MerchantReviewsNotifier, AsyncValue<MerchantReviewsDashboard>>((ref) {
  return MerchantReviewsNotifier(ref);
});
