// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faq_category_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FaqCategoryDto _$FaqCategoryDtoFromJson(Map<String, dynamic> json) =>
    FaqCategoryDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      iconName: json['icon_name'] as String?,
      displayOrder: (json['display_order'] as num).toInt(),
      isActive: json['is_active'] as bool,
      articlesCount: (json['articles_count'] as num?)?.toInt(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$FaqCategoryDtoToJson(FaqCategoryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon_name': instance.iconName,
      'display_order': instance.displayOrder,
      'is_active': instance.isActive,
      'articles_count': instance.articlesCount,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
