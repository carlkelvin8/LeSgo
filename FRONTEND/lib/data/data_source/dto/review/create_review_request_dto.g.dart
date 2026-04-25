// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_review_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateReviewRequestDto _$CreateReviewRequestDtoFromJson(
  Map<String, dynamic> json,
) => CreateReviewRequestDto(
  reviewableType: json['reviewable_type'] as String,
  reviewableId: (json['reviewable_id'] as num).toInt(),
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String?,
);

Map<String, dynamic> _$CreateReviewRequestDtoToJson(
  CreateReviewRequestDto instance,
) => <String, dynamic>{
  'reviewable_type': instance.reviewableType,
  'reviewable_id': instance.reviewableId,
  'rating': instance.rating,
  'comment': instance.comment,
};
