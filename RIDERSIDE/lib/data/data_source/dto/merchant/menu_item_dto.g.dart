// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuItemDto _$MenuItemDtoFromJson(Map<String, dynamic> json) => MenuItemDto(
      id: _parseInt(json['id']),
      partnerId: _parseInt(json['partner_id']),
      menuCategoryId: _parseInt(json['menu_category_id']),
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: _parseImageUrl(_readImageUrlField(json, 'image_url')),
      price: _parseDouble(json['price']),
      originalPrice: _parseDoubleNullable(json['original_price']),
      unit: json['unit'] as String?,
      isAvailable: _parseBool(json['is_available']),
      isPopular: _parseBoolNullable(json['is_popular']),
      isFeatured: _parseBoolNullable(json['is_featured']),
      isBestSeller: _parseBoolNullable(json['is_best_seller']),
      requiresPrescription: _parseBoolNullable(json['requires_prescription']),
      sortOrder: _parseIntNullable(json['sort_order']),
      stockCount: _parseIntNullable(json['stock_count']),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      options: json['options'] as Map<String, dynamic>?,
      category: json['category'] == null
          ? null
          : MenuCategoryDto.fromJson(json['category'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MenuItemDtoToJson(MenuItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'partner_id': instance.partnerId,
      'menu_category_id': instance.menuCategoryId,
      'name': instance.name,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'price': instance.price,
      'original_price': instance.originalPrice,
      'unit': instance.unit,
      'is_available': instance.isAvailable,
      'is_popular': instance.isPopular,
      'is_featured': instance.isFeatured,
      'is_best_seller': instance.isBestSeller,
      'requires_prescription': instance.requiresPrescription,
      'sort_order': instance.sortOrder,
      'stock_count': instance.stockCount,
      'tags': instance.tags,
      'options': instance.options,
      'category': instance.category,
    };

MenuCategoryDto _$MenuCategoryDtoFromJson(Map<String, dynamic> json) =>
    MenuCategoryDto(
      id: _parseInt(json['id']),
      partnerId: _parseInt(json['partner_id']),
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: _parseImageUrl(_readImageUrlField(json, 'image_url')),
      iconEmoji: json['icon_emoji'] as String?,
      isActive: _parseBoolNullable(json['is_active']) ?? true,
      sortOrder: _parseIntNullable(json['sort_order']),
      availableItems: (json['available_items'] as List<dynamic>?)
          ?.map((e) => MenuItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MenuCategoryDtoToJson(MenuCategoryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'partner_id': instance.partnerId,
      'name': instance.name,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'icon_emoji': instance.iconEmoji,
      'is_active': instance.isActive,
      'sort_order': instance.sortOrder,
      'available_items': instance.availableItems,
    };
