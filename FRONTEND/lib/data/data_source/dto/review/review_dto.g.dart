// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewDto _$ReviewDtoFromJson(Map<String, dynamic> json) => ReviewDto(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  reviewableType: json['reviewable_type'] as String,
  reviewableId: (json['reviewable_id'] as num).toInt(),
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String?,
  helpfulCount: (json['helpful_count'] as num).toInt(),
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
  userName: json['user_name'] as String?,
  userPhoto: json['user_photo'] as String?,
);

Map<String, dynamic> _$ReviewDtoToJson(ReviewDto instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'reviewable_type': instance.reviewableType,
  'reviewable_id': instance.reviewableId,
  'rating': instance.rating,
  'comment': instance.comment,
  'helpful_count': instance.helpfulCount,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'user_name': instance.userName,
  'user_photo': instance.userPhoto,
};
