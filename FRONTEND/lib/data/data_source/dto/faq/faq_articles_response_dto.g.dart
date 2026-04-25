// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faq_articles_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FaqArticlesResponseDto _$FaqArticlesResponseDtoFromJson(
  Map<String, dynamic> json,
) => FaqArticlesResponseDto(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => FaqArticleDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FaqArticlesResponseDtoToJson(
  FaqArticlesResponseDto instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

FaqArticleResponseDto _$FaqArticleResponseDtoFromJson(
  Map<String, dynamic> json,
) => FaqArticleResponseDto(
  success: json['success'] as bool,
  data: FaqArticleDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FaqArticleResponseDtoToJson(
  FaqArticleResponseDto instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};
