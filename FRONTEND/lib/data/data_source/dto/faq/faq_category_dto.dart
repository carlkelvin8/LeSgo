import 'package:json_annotation/json_annotation.dart';

part 'faq_category_dto.g.dart';

@JsonSerializable()
class FaqCategoryDto {
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'icon_name')
  final String? iconName;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'articles_count')
  final int? articlesCount;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  FaqCategoryDto({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    required this.displayOrder,
    required this.isActive,
    this.articlesCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FaqCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$FaqCategoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FaqCategoryDtoToJson(this);
}
