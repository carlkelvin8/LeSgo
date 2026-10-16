// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewDto _$ReviewDtoFromJson(Map<String, dynamic> json) => ReviewDto(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  reviewableType: json['driver_id'] != null ? 'driver' : 'service',
  reviewableId: ((json['driver_id'] ?? json['service_id'] ?? 0) as num).toInt(),
  rating: (json['overall_rating'] as num).toInt(),
  comment: json['review_comment'] as String?,
  helpfulCount: (json['helpful_count'] as num?)?.toInt() ?? 0,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
  userName:
      (json['user'] as Map<String, dynamic>?)?['name'] as String? ??
      json['user_name'] as String?,
  userPhoto:
      (json['user'] as Map<String, dynamic>?)?['profile_photo_url']
          as String? ??
      json['user_photo'] as String?,
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
