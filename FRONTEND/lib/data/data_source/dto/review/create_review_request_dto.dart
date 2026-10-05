import 'package:json_annotation/json_annotation.dart';

part 'create_review_request_dto.g.dart';

@JsonSerializable()
class CreateReviewRequestDto {
  @JsonKey(name: 'order_id')
  final int orderId;
  @JsonKey(name: 'overall_rating')
  final int rating;
  @JsonKey(name: 'review_comment')
  final String? comment;

  CreateReviewRequestDto({
    required this.orderId,
    required this.rating,
    this.comment,
  });

  factory CreateReviewRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateReviewRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateReviewRequestDtoToJson(this);
}
