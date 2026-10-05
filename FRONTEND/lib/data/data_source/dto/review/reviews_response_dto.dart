import 'package:json_annotation/json_annotation.dart';
import 'review_dto.dart';

part 'reviews_response_dto.g.dart';

@JsonSerializable()
class ReviewsResponseDto {
  final bool success;
  final List<ReviewDto> data;
  final Map<String, dynamic>? meta;

  ReviewsResponseDto({
    required this.success,
    required this.data,
    this.meta,
  });

  factory ReviewsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewsResponseDtoToJson(this);
}

@JsonSerializable()
class ReviewResponseDto {
  final bool success;
  final String? message;
  final ReviewDto data;

  ReviewResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory ReviewResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewResponseDtoToJson(this);
}

@JsonSerializable()
class ReviewStatisticsDto {
  @JsonKey(name: 'average_rating')
  final double averageRating;
  @JsonKey(name: 'total_reviews')
  final int totalReviews;
  @JsonKey(name: 'rating_distribution')
  final Map<String, int> ratingDistribution;

  ReviewStatisticsDto({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory ReviewStatisticsDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewStatisticsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewStatisticsDtoToJson(this);
}

@JsonSerializable()
class ReviewStatisticsResponseDto {
  final bool success;
  final ReviewStatisticsDto data;

  ReviewStatisticsResponseDto({
    required this.success,
    required this.data,
  });

  factory ReviewStatisticsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewStatisticsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewStatisticsResponseDtoToJson(this);
}
