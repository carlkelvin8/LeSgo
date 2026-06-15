import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';

class RiderRatingSummary {
  final double overallRating;
  final int totalReviews;
  final Map<int, int> ratingBreakdown;

  const RiderRatingSummary({
    required this.overallRating,
    required this.totalReviews,
    required this.ratingBreakdown,
  });
}

class RiderReview {
  final String customerName;
  final int rating;
  final String comment;
  final DateTime date;

  const RiderReview({
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class RiderRatingState {
  final RiderRatingSummary summary;
  final List<RiderReview> reviews;
  final List<double> weeklyScores;

  const RiderRatingState({
    required this.summary,
    required this.reviews,
    required this.weeklyScores,
  });
}

final riderRatingProvider =
    FutureProvider.autoDispose<RiderRatingState>((ref) async {
  try {
    final data = await ApiService.dio.get('/v1/drivers/ratings');
    final body = (data.data['data'] ?? data.data) as Map<String, dynamic>;

    final summaryRaw =
        (body['summary'] as Map<String, dynamic>?) ?? {};
    final reviewsRaw = body['reviews'] as List<dynamic>? ?? [];
    final scoresRaw = body['weekly_scores'] as List<dynamic>? ?? [];

    final breakdownRaw =
        (summaryRaw['rating_breakdown'] as Map<String, dynamic>?) ?? {};
    final ratingBreakdown = <int, int>{};
    for (int star = 1; star <= 5; star++) {
      ratingBreakdown[star] =
          (breakdownRaw[star.toString()] as num?)?.toInt() ?? 0;
    }

    final reviews = reviewsRaw.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return RiderReview(
        customerName: map['customer_name']?.toString() ?? 'Customer',
        rating: (map['rating'] as num?)?.toInt() ?? 5,
        comment: map['comment']?.toString() ?? '',
        date: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'].toString())?.toLocal() ??
                DateTime.now()
            : DateTime.now(),
      );
    }).toList();

    final weeklyScores =
        scoresRaw.map((s) => (s as num?)?.toDouble() ?? 0.0).toList();

    return RiderRatingState(
      summary: RiderRatingSummary(
        overallRating:
            (summaryRaw['overall_rating'] as num?)?.toDouble() ?? 0.0,
        totalReviews:
            (summaryRaw['total_reviews'] as num?)?.toInt() ?? 0,
        ratingBreakdown: ratingBreakdown,
      ),
      reviews: reviews,
      weeklyScores: weeklyScores,
    );
  } catch (e) {
    AppLogger.error('Failed to load rider ratings, using fallback', e);
    return _mockRatingState();
  }
});

RiderRatingState _mockRatingState() {
  return RiderRatingState(
    summary: RiderRatingSummary(
      overallRating: 4.6,
      totalReviews: 128,
      ratingBreakdown: {5: 78, 4: 32, 3: 12, 2: 4, 1: 2},
    ),
    reviews: [
      RiderReview(
        customerName: 'Maria Santos',
        rating: 5,
        comment: 'Very fast and professional rider!',
        date: DateTime(2026, 6, 12),
      ),
      RiderReview(
        customerName: 'Juan Dela Cruz',
        rating: 4,
        comment: 'Good service, arrived on time.',
        date: DateTime(2026, 6, 10),
      ),
      RiderReview(
        customerName: 'Ana Gonzales',
        rating: 5,
        comment: 'Friendly and handled my package with care.',
        date: DateTime(2026, 6, 8),
      ),
      RiderReview(
        customerName: 'Carlos Reyes',
        rating: 3,
        comment: 'Decent but took longer than expected.',
        date: DateTime(2026, 6, 5),
      ),
      RiderReview(
        customerName: 'Liza Mercado',
        rating: 5,
        comment: 'Best rider in the area! Highly recommended.',
        date: DateTime(2026, 6, 3),
      ),
      RiderReview(
        customerName: 'Pedro Lopez',
        rating: 4,
        comment: 'Smooth delivery, thanks!',
        date: DateTime(2026, 6, 1),
      ),
    ],
    weeklyScores: [4.2, 4.5, 4.3, 4.7, 4.6, 4.8, 4.6],
  );
}
