import 'package:json_annotation/json_annotation.dart';

part 'faq_article_dto.g.dart';

@JsonSerializable()
class FaqArticleDto {
  final int id;
  @JsonKey(name: 'category_id')
  final int categoryId;
  final String title;
  final String content;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'is_featured')
  final bool isFeatured;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'view_count')
  final int viewCount;
  @JsonKey(name: 'helpful_count')
  final int helpfulCount;
  @JsonKey(name: 'not_helpful_count')
  final int notHelpfulCount;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  FaqArticleDto({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.content,
    required this.displayOrder,
    required this.isFeatured,
    required this.isActive,
    required this.viewCount,
    required this.helpfulCount,
    required this.notHelpfulCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FaqArticleDto.fromJson(Map<String, dynamic> json) =>
      _$FaqArticleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FaqArticleDtoToJson(this);
}
