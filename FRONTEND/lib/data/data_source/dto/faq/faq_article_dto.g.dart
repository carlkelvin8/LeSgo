// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faq_article_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FaqArticleDto _$FaqArticleDtoFromJson(Map<String, dynamic> json) =>
    FaqArticleDto(
      id: (json['id'] as num).toInt(),
      categoryId: (json['category_id'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      displayOrder: (json['display_order'] as num).toInt(),
      isFeatured: json['is_featured'] as bool,
      isActive: json['is_active'] as bool,
      viewCount: (json['view_count'] as num).toInt(),
      helpfulCount: (json['helpful_count'] as num).toInt(),
      notHelpfulCount: (json['not_helpful_count'] as num).toInt(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$FaqArticleDtoToJson(FaqArticleDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category_id': instance.categoryId,
      'title': instance.title,
      'content': instance.content,
      'display_order': instance.displayOrder,
      'is_featured': instance.isFeatured,
      'is_active': instance.isActive,
      'view_count': instance.viewCount,
      'helpful_count': instance.helpfulCount,
      'not_helpful_count': instance.notHelpfulCount,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
