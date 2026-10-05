// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faq_categories_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FaqCategoriesResponseDto _$FaqCategoriesResponseDtoFromJson(
  Map<String, dynamic> json,
) => FaqCategoriesResponseDto(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => FaqCategoryDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FaqCategoriesResponseDtoToJson(
  FaqCategoriesResponseDto instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};
