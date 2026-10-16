// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_review_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateReviewRequestDto _$CreateReviewRequestDtoFromJson(
  Map<String, dynamic> json,
) => CreateReviewRequestDto(
  orderId: (json['order_id'] as num).toInt(),
  rating: (json['overall_rating'] as num).toInt(),
  comment: json['review_comment'] as String?,
);

Map<String, dynamic> _$CreateReviewRequestDtoToJson(
  CreateReviewRequestDto instance,
) => <String, dynamic>{
  'order_id': instance.orderId,
  'overall_rating': instance.rating,
  'review_comment': instance.comment,
};
