import 'package:json_annotation/json_annotation.dart';

part 'menu_item_dto.g.dart';

@JsonSerializable()
class MenuItemDto {
  final int id;
  @JsonKey(name: 'partner_id')
  final int partnerId;
  @JsonKey(name: 'menu_category_id')
  final int menuCategoryId;
  final String name;
  final String? description;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final double price;
  @JsonKey(name: 'original_price')
  final double? originalPrice;
  final String? unit;
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  @JsonKey(name: 'is_popular')
  final bool? isPopular;
  @JsonKey(name: 'is_featured')
  final bool? isFeatured;
  @JsonKey(name: 'is_best_seller')
  final bool? isBestSeller;
  @JsonKey(name: 'requires_prescription')
  final bool? requiresPrescription;
  @JsonKey(name: 'sort_order')
  final int? sortOrder;
  final List<String>? tags;
  final Map<String, dynamic>? options;
  
  // From relationship
  final MenuCategoryDto? category;
  
  MenuItemDto({
    required this.id,
    required this.partnerId,
    required this.menuCategoryId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.price,
    this.originalPrice,
    this.unit,
    required this.isAvailable,
    this.isPopular,
    this.isFeatured,
    this.isBestSeller,
    this.requiresPrescription,
    this.sortOrder,
    this.tags,
    this.options,
    this.category,
  });
  
  factory MenuItemDto.fromJson(Map<String, dynamic> json) => 
      _$MenuItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MenuItemDtoToJson(this);
}

@JsonSerializable()
class MenuCategoryDto {
  final int id;
  @JsonKey(name: 'partner_id')
  final int partnerId;
  final String name;
  final String? description;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'icon_emoji')
  final String? iconEmoji;
  @JsonKey(name: 'is_active', defaultValue: true)
  final bool? isActive;
  @JsonKey(name: 'sort_order')
  final int? sortOrder;
  
  // Relationship - items in this category
  @JsonKey(name: 'available_items')
  final List<MenuItemDto>? availableItems;
  
  MenuCategoryDto({
    required this.id,
    required this.partnerId,
    required this.name,
    this.description,
    this.imageUrl,
    this.iconEmoji,
    this.isActive = true,
    this.sortOrder,
    this.availableItems,
  });
  
  factory MenuCategoryDto.fromJson(Map<String, dynamic> json) => 
      _$MenuCategoryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MenuCategoryDtoToJson(this);
}
