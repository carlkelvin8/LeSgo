import 'package:json_annotation/json_annotation.dart';

part 'create_review_request_dto.g.dart';

@JsonSerializable()
class CreateReviewRequestDto {
  @JsonKey(name: 'reviewable_type')
  final String reviewableType;
  @JsonKey(name: 'reviewable_id')
  final int reviewableId;
  final int rating;
  final String? comment;

  CreateReviewRequestDto({
    required this.reviewableType,
    required this.reviewableId,
    required this.rating,
    this.comment,
  });

  factory CreateReviewRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateReviewRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateReviewRequestDtoToJson(this);
}
