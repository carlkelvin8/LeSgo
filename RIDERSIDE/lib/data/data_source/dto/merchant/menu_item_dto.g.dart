// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuItemDto _$MenuItemDtoFromJson(Map<String, dynamic> json) => MenuItemDto(
  id: (json['id'] as num).toInt(),
  partnerId: (json['partner_id'] as num).toInt(),
  menuCategoryId: (json['menu_category_id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  imageUrl: json['image_url'] as String?,
  price: (json['price'] as num).toDouble(),
  originalPrice: (json['original_price'] as num?)?.toDouble(),
  unit: json['unit'] as String?,
  isAvailable: json['is_available'] as bool,
  isPopular: json['is_popular'] as bool?,
  isFeatured: json['is_featured'] as bool?,
  isBestSeller: json['is_best_seller'] as bool?,
  requiresPrescription: json['requires_prescription'] as bool?,
  sortOrder: (json['sort_order'] as num?)?.toInt(),
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
      'tags': instance.tags,
      'options': instance.options,
      'category': instance.category,
    };

MenuCategoryDto _$MenuCategoryDtoFromJson(Map<String, dynamic> json) =>
    MenuCategoryDto(
      id: (json['id'] as num).toInt(),
      partnerId: (json['partner_id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      iconEmoji: json['icon_emoji'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt(),
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
