import 'package:json_annotation/json_annotation.dart';

part 'review_dto.g.dart';

@JsonSerializable()
class ReviewDto {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'reviewable_type')
  final String reviewableType;
  @JsonKey(name: 'reviewable_id')
  final int reviewableId;
  final int rating;
  final String? comment;
  @JsonKey(name: 'helpful_count')
  final int helpfulCount;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  
  // Optional user info
  @JsonKey(name: 'user_name')
  final String? userName;
  @JsonKey(name: 'user_photo')
  final String? userPhoto;

  ReviewDto({
    required this.id,
    required this.userId,
    required this.reviewableType,
    required this.reviewableId,
    required this.rating,
    this.comment,
    required this.helpfulCount,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userPhoto,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewDtoToJson(this);
}
