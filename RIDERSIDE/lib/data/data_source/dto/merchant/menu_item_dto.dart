import 'package:json_annotation/json_annotation.dart';

part 'menu_item_dto.g.dart';

int _parseInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _parseIntNullable(dynamic value) {
  if (value == null) return null;
  return _parseInt(value);
}

double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

double _parseDouble(dynamic value, [double fallback = 0.0]) {
  return _parseDoubleNullable(value) ?? fallback;
}

bool _parseBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

bool? _parseBoolNullable(dynamic value) {
  if (value == null) return null;
  return _parseBool(value);
}

Object? _readImageUrlField(Map json, String key) {
  for (final field in [
    'image_url',
    'image',
    'thumbnail_url',
    'photo_url',
    'image_path',
  ]) {
    final value = json[field];
    if (value != null) return value;
  }
  return null;
}

String? _parseImageUrl(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is Map) {
    for (final key in ['url', 'image_url', 'path', 'full_url', 'src']) {
      final nested = value[key];
      if (nested != null) {
        final parsed = _parseImageUrl(nested);
        if (parsed != null) return parsed;
      }
    }
  }
  return null;
}

@JsonSerializable()
class MenuItemDto {
  @JsonKey(fromJson: _parseInt)
  final int id;
  @JsonKey(name: 'partner_id', fromJson: _parseInt)
  final int partnerId;
  @JsonKey(name: 'menu_category_id', fromJson: _parseInt)
  final int menuCategoryId;
  final String name;
  final String? description;
  @JsonKey(name: 'image_url', readValue: _readImageUrlField, fromJson: _parseImageUrl)
  final String? imageUrl;
  @JsonKey(fromJson: _parseDouble)
  final double price;
  @JsonKey(name: 'original_price', fromJson: _parseDoubleNullable)
  final double? originalPrice;
  final String? unit;
  @JsonKey(name: 'is_available', fromJson: _parseBool)
  final bool isAvailable;
  @JsonKey(name: 'is_popular', fromJson: _parseBoolNullable)
  final bool? isPopular;
  @JsonKey(name: 'is_featured', fromJson: _parseBoolNullable)
  final bool? isFeatured;
  @JsonKey(name: 'is_best_seller', fromJson: _parseBoolNullable)
  final bool? isBestSeller;
  @JsonKey(name: 'requires_prescription', fromJson: _parseBoolNullable)
  final bool? requiresPrescription;
  @JsonKey(name: 'sort_order', fromJson: _parseIntNullable)
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
  @JsonKey(fromJson: _parseInt)
  final int id;
  @JsonKey(name: 'partner_id', fromJson: _parseInt)
  final int partnerId;
  final String name;
  final String? description;
  @JsonKey(name: 'image_url', readValue: _readImageUrlField, fromJson: _parseImageUrl)
  final String? imageUrl;
  @JsonKey(name: 'icon_emoji')
  final String? iconEmoji;
  @JsonKey(name: 'is_active', defaultValue: true, fromJson: _parseBoolNullable)
  final bool? isActive;
  @JsonKey(name: 'sort_order', fromJson: _parseIntNullable)
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
