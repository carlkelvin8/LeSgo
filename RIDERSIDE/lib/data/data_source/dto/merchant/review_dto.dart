class ReviewDto {
  final int id;
  final int userId;
  final String reviewableType;
  final int reviewableId;
  final int rating;
  final String? comment;
  final int helpfulCount;
  final String createdAt;
  final String updatedAt;
  final String? userName;
  final String? userPhoto;

  ReviewDto({
    required this.id,
    required this.userId,
    required this.reviewableType,
    required this.reviewableId,
    required this.rating,
    this.comment,
    this.helpfulCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userPhoto,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String? userName = json['user_name']?.toString();
    String? userPhoto = json['user_photo']?.toString();

    if (user is Map) {
      userName ??= user['name']?.toString();
      userPhoto ??= user['profile_photo_url']?.toString() ??
          user['profile_picture']?.toString();
    }

    return ReviewDto(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      reviewableType: json['reviewable_type']?.toString() ?? 'partner',
      reviewableId: (json['reviewable_id'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment']?.toString(),
      helpfulCount: (json['helpful_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      userName: userName,
      userPhoto: userPhoto,
    );
  }
}

class ReviewStatisticsDto {
  final double averageRating;
  final int totalReviews;
  final Map<String, int> ratingDistribution;

  ReviewStatisticsDto({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory ReviewStatisticsDto.fromJson(Map<String, dynamic> json) {
    final distributionRaw = json['rating_distribution'];
    final distribution = <String, int>{};
    if (distributionRaw is Map) {
      for (final entry in distributionRaw.entries) {
        distribution[entry.key.toString()] = (entry.value as num).toInt();
      }
    }

    return ReviewStatisticsDto(
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      ratingDistribution: distribution,
    );
  }

  static ReviewStatisticsDto fromReviews(
    List<ReviewDto> reviews, {
    double? fallbackAverage,
    int? fallbackTotal,
  }) {
    if (reviews.isEmpty) {
      return ReviewStatisticsDto(
        averageRating: fallbackAverage ?? 0,
        totalReviews: fallbackTotal ?? 0,
        ratingDistribution: const {},
      );
    }

    final distribution = <String, int>{
      '5': 0,
      '4': 0,
      '3': 0,
      '2': 0,
      '1': 0,
    };

    var sum = 0;
    for (final review in reviews) {
      sum += review.rating;
      final key = review.rating.clamp(1, 5).toString();
      distribution[key] = (distribution[key] ?? 0) + 1;
    }

    return ReviewStatisticsDto(
      averageRating: sum / reviews.length,
      totalReviews: reviews.length,
      ratingDistribution: distribution,
    );
  }
}

class MerchantReviewsPage {
  final List<ReviewDto> reviews;
  final int currentPage;
  final int lastPage;
  final int total;

  MerchantReviewsPage({
    required this.reviews,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}
