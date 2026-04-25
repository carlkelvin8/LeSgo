import 'package:json_annotation/json_annotation.dart';
import 'faq_article_dto.dart';

part 'faq_articles_response_dto.g.dart';

@JsonSerializable()
class FaqArticlesResponseDto {
  final bool success;
  final List<FaqArticleDto> data;

  FaqArticlesResponseDto({
    required this.success,
    required this.data,
  });

  factory FaqArticlesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FaqArticlesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FaqArticlesResponseDtoToJson(this);
}

@JsonSerializable()
class FaqArticleResponseDto {
  final bool success;
  final FaqArticleDto data;

  FaqArticleResponseDto({
    required this.success,
    required this.data,
  });

  factory FaqArticleResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FaqArticleResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FaqArticleResponseDtoToJson(this);
}
