import 'package:json_annotation/json_annotation.dart';
import 'faq_category_dto.dart';

part 'faq_categories_response_dto.g.dart';

@JsonSerializable()
class FaqCategoriesResponseDto {
  final bool success;
  final List<FaqCategoryDto> data;

  FaqCategoriesResponseDto({
    required this.success,
    required this.data,
  });

  factory FaqCategoriesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FaqCategoriesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FaqCategoriesResponseDtoToJson(this);
}
