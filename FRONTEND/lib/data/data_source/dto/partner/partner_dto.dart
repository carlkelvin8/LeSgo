import 'package:json_annotation/json_annotation.dart';

part 'partner_dto.g.dart';

int _parseInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
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

bool? _parseBoolNullable(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

bool _parseBool(dynamic value, [bool fallback = false]) {
  return _parseBoolNullable(value) ?? fallback;
}

List<String>? _parseStringList(dynamic value) {
  if (value is List) {
    return value
        .where((item) => item != null)
        .map((item) => item.toString())
        .toList();
  }
  return null;
}

@JsonSerializable()
class PartnerDto {
  final int id;
  final String name;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  @JsonKey(name: 'cover_image_url')
  final String? coverImageUrl;
  final String? description;
  final String? category;
  final List<String>? tags;
  @JsonKey(name: 'cuisine_types')
  final List<String>? cuisineTypes;
  final double? rating;
  @JsonKey(name: 'total_reviews')
  final int? totalReviews;
  @JsonKey(name: 'delivery_fee')
  final double? deliveryFee;
  @JsonKey(name: 'min_order_amount')
  final int? minOrderAmount;
  @JsonKey(name: 'estimated_delivery_minutes')
  final int? estimatedDeliveryMinutes;
  @JsonKey(name: 'is_open')
  final bool? isOpen;
  @JsonKey(name: 'is_featured')
  final bool? isFeatured;
  final String? status;

  PartnerDto({
    required this.id,
    required this.name,
    this.logoUrl,
    this.coverImageUrl,
    this.description,
    this.category,
    this.tags,
    this.cuisineTypes,
    this.rating,
    this.totalReviews,
    this.deliveryFee,
    this.minOrderAmount,
    this.estimatedDeliveryMinutes,
    this.isOpen,
    this.isFeatured,
    this.status,
  });

  factory PartnerDto.fromJson(Map<String, dynamic> json) =>
      _$PartnerDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PartnerDtoToJson(this);
}

@JsonSerializable()
class PartnersResponseDto {
  final bool success;
  final List<PartnerDto> data;
  final PaginationMetaDto? meta;

  PartnersResponseDto({required this.success, required this.data, this.meta});

  factory PartnersResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PartnersResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PartnersResponseDtoToJson(this);
}

@JsonSerializable()
class PaginationMetaDto {
  final int total;
  @JsonKey(name: 'per_page')
  final int perPage;
  @JsonKey(name: 'current_page')
  final int currentPage;
  @JsonKey(name: 'last_page')
  final int lastPage;
  final int from;
  final int to;
  @JsonKey(name: 'has_more')
  final bool hasMore;

  PaginationMetaDto({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
    required this.hasMore,
  });

  factory PaginationMetaDto.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationMetaDtoToJson(this);
}

// Legacy DTO for backward compatibility
@JsonSerializable()
class PaginatedPartnersDto {
  final List<PartnerDto> data;
  @JsonKey(name: 'current_page')
  final int currentPage;
  @JsonKey(name: 'last_page')
  final int lastPage;
  @JsonKey(name: 'per_page')
  final int perPage;
  final int total;

  PaginatedPartnersDto({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginatedPartnersDto.fromJson(Map<String, dynamic> json) =>
      _$PaginatedPartnersDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PaginatedPartnersDtoToJson(this);
}

@JsonSerializable()
class MenuItemDto {
  final int id;
  @JsonKey(name: 'partner_id')
  final int partnerId;
  @JsonKey(name: 'menu_category_id')
  final int? menuCategoryId;
  final String name;
  final String? description;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final double price;
  @JsonKey(name: 'original_price')
  final double? originalPrice;
  final String? unit;
  @JsonKey(name: 'is_available')
  final bool? isAvailable;
  @JsonKey(name: 'is_popular')
  final bool? isPopular;
  @JsonKey(name: 'is_featured')
  final bool? isFeatured;
  final List<String>? tags;

  MenuItemDto({
    required this.id,
    required this.partnerId,
    this.menuCategoryId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.price,
    this.originalPrice,
    this.unit,
    this.isAvailable,
    this.isPopular,
    this.isFeatured,
    this.tags,
  });

  factory MenuItemDto.fromJson(Map<String, dynamic> json) =>
      _$MenuItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MenuItemDtoToJson(this);
}

@JsonSerializable()
class MenuCategoryDto {
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'available_items')
  final List<MenuItemDto>? availableItems;

  MenuCategoryDto({
    required this.id,
    required this.name,
    this.description,
    this.availableItems,
  });

  factory MenuCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$MenuCategoryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MenuCategoryDtoToJson(this);
}

@JsonSerializable()
class PartnerMenuResponseDto {
  final bool success;
  final PartnerMenuDataDto data;

  PartnerMenuResponseDto({required this.success, required this.data});

  factory PartnerMenuResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PartnerMenuResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PartnerMenuResponseDtoToJson(this);
}

@JsonSerializable()
class PartnerMenuDataDto {
  final PartnerDto partner;
  final List<MenuCategoryDto> categories;

  PartnerMenuDataDto({required this.partner, required this.categories});

  factory PartnerMenuDataDto.fromJson(Map<String, dynamic> json) =>
      _$PartnerMenuDataDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PartnerMenuDataDtoToJson(this);
}
