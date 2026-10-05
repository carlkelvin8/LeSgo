import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../auth/rider_auth_provider.dart';

class RiderRatingSummary {
  final double overallRating;
  final int totalReviews;
  final Map<int, int> ratingBreakdown;

  const RiderRatingSummary({
    required this.overallRating,
    required this.totalReviews,
    required this.ratingBreakdown,
  });

  static RiderRatingSummary empty() => const RiderRatingSummary(
        overallRating: 0,
        totalReviews: 0,
        ratingBreakdown: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      );
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

  static RiderRatingState empty() => RiderRatingState(
        summary: RiderRatingSummary.empty(),
        reviews: const [],
        weeklyScores: const [],
      );
}

final riderRatingProvider =
    FutureProvider.autoDispose<RiderRatingState>((ref) async {
  final user = ref.watch(riderAuthProvider).user;
  if (user == null) {
    throw StateError('Not signed in');
  }

  final driverId = user.id;

  final statsResponse = await ApiService.dio.get(
    '/v1/reviews/statistics',
    queryParameters: {'driver_id': driverId},
  );
  final statsBody =
      (statsResponse.data['data'] ?? statsResponse.data) as Map<String, dynamic>;

  final reviewsResponse = await ApiService.dio.get(
    '/v1/reviews',
    queryParameters: {
      'driver_id': driverId,
      'per_page': 50,
    },
  );
  final reviewsRaw = _extractReviewList(reviewsResponse.data);

  final distributionRaw =
      (statsBody['rating_distribution'] as Map<String, dynamic>?) ?? {};
  final ratingBreakdown = <int, int>{};
  for (int star = 1; star <= 5; star++) {
    ratingBreakdown[star] =
        (distributionRaw[star.toString()] as num?)?.toInt() ?? 0;
  }

  final reviews = reviewsRaw
      .map(_parseReview)
      .where((review) => review.rating > 0)
      .toList();

  final summary = RiderRatingSummary(
    overallRating: (statsBody['average_rating'] as num?)?.toDouble() ??
        _averageFromReviews(reviews),
    totalReviews: (statsBody['total_reviews'] as num?)?.toInt() ??
        reviews.length,
    ratingBreakdown: ratingBreakdown.values.every((count) => count == 0)
        ? _breakdownFromReviews(reviews)
        : ratingBreakdown,
  );

  return RiderRatingState(
    summary: summary,
    reviews: reviews,
    weeklyScores: _computeWeeklyScores(reviews),
  );
});

List<Map<String, dynamic>> _extractReviewList(dynamic raw) {
  final root = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  final data = root['data'] ?? root;

  if (data is List) {
    return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    final list = map['data'];
    if (list is List) {
      return list.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }
  }

  return const [];
}

RiderReview _parseReview(Map<String, dynamic> map) {
  final user = map['user'];
  final isAnonymous = map['is_anonymous'] == true;
  String customerName = 'Customer';
  if (!isAnonymous && user is Map) {
    final name = user['name']?.toString().trim();
    if (name != null && name.isNotEmpty) {
      customerName = name;
    }
  } else if (isAnonymous) {
    customerName = 'Anonymous';
  }

  final rating = (map['driver_rating'] as num?)?.toInt() ??
      (map['overall_rating'] as num?)?.toInt() ??
      0;

  return RiderReview(
    customerName: customerName,
    rating: rating,
    comment: map['review_comment']?.toString() ?? '',
    date: map['created_at'] != null
        ? DateTime.tryParse(map['created_at'].toString())?.toLocal() ??
            DateTime.now()
        : DateTime.now(),
  );
}

double _averageFromReviews(List<RiderReview> reviews) {
  if (reviews.isEmpty) return 0;
  final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
  return total / reviews.length;
}

Map<int, int> _breakdownFromReviews(List<RiderReview> reviews) {
  final breakdown = <int, int>{for (int star = 1; star <= 5; star++) star: 0};
  for (final review in reviews) {
    final star = review.rating.clamp(1, 5);
    breakdown[star] = (breakdown[star] ?? 0) + 1;
  }
  return breakdown;
}

List<double> _computeWeeklyScores(List<RiderReview> reviews) {
  if (reviews.isEmpty) return const [];

  final now = DateTime.now();
  final scores = <double>[];

  for (int week = 6; week >= 0; week--) {
    final weekEnd = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: week * 7));
    final weekStart = weekEnd.subtract(const Duration(days: 7));

    final weekReviews = reviews.where((review) {
      return !review.date.isBefore(weekStart) && review.date.isBefore(weekEnd);
    }).toList();

    if (weekReviews.isEmpty) {
      scores.add(0);
    } else {
      final total =
          weekReviews.fold<int>(0, (sum, review) => sum + review.rating);
      scores.add(total / weekReviews.length);
    }
  }

  return scores;
}
