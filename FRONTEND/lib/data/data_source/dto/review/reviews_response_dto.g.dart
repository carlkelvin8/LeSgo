// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reviews_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewsResponseDto _$ReviewsResponseDtoFromJson(Map<String, dynamic> json) =>
    ReviewsResponseDto(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => ReviewDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ReviewsResponseDtoToJson(ReviewsResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'meta': instance.meta,
    };

ReviewResponseDto _$ReviewResponseDtoFromJson(Map<String, dynamic> json) =>
    ReviewResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: ReviewDto.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReviewResponseDtoToJson(ReviewResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

ReviewStatisticsDto _$ReviewStatisticsDtoFromJson(Map<String, dynamic> json) =>
    ReviewStatisticsDto(
      averageRating: (json['average_rating'] as num).toDouble(),
      totalReviews: (json['total_reviews'] as num).toInt(),
      ratingDistribution: Map<String, int>.from(
        json['rating_distribution'] as Map,
      ),
    );

Map<String, dynamic> _$ReviewStatisticsDtoToJson(
  ReviewStatisticsDto instance,
) => <String, dynamic>{
  'average_rating': instance.averageRating,
  'total_reviews': instance.totalReviews,
  'rating_distribution': instance.ratingDistribution,
};

ReviewStatisticsResponseDto _$ReviewStatisticsResponseDtoFromJson(
  Map<String, dynamic> json,
) => ReviewStatisticsResponseDto(
  success: json['success'] as bool,
  data: ReviewStatisticsDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ReviewStatisticsResponseDtoToJson(
  ReviewStatisticsResponseDto instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};
