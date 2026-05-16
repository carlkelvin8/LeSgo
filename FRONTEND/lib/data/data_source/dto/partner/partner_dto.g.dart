// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PartnerDto _$PartnerDtoFromJson(Map<String, dynamic> json) => PartnerDto(
  id: _parseInt(json['id']),
  name: json['name']?.toString() ?? 'Unknown Partner',
  logoUrl: json['logo_url'] as String?,
  coverImageUrl: json['cover_image_url'] as String?,
  description: json['description'] as String?,
  category: json['category'] as String?,
  tags: _parseStringList(json['tags']),
  cuisineTypes: _parseStringList(json['cuisine_types']),
  rating: _parseDoubleNullable(json['rating']),
  totalReviews: json['total_reviews'] == null
      ? null
      : _parseInt(json['total_reviews']),
  deliveryFee: _parseDoubleNullable(json['delivery_fee']),
  minOrderAmount: json['min_order_amount'] == null
      ? null
      : _parseInt(json['min_order_amount']),
  estimatedDeliveryMinutes: json['estimated_delivery_minutes'] == null
      ? null
      : _parseInt(json['estimated_delivery_minutes']),
  isOpen: _parseBoolNullable(json['is_open']),
  isFeatured: _parseBoolNullable(json['is_featured']),
  status: json['status'] as String?,
);

Map<String, dynamic> _$PartnerDtoToJson(PartnerDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'logo_url': instance.logoUrl,
      'cover_image_url': instance.coverImageUrl,
      'description': instance.description,
      'category': instance.category,
      'tags': instance.tags,
      'cuisine_types': instance.cuisineTypes,
      'rating': instance.rating,
      'total_reviews': instance.totalReviews,
      'delivery_fee': instance.deliveryFee,
      'min_order_amount': instance.minOrderAmount,
      'estimated_delivery_minutes': instance.estimatedDeliveryMinutes,
      'is_open': instance.isOpen,
      'is_featured': instance.isFeatured,
      'status': instance.status,
    };

PartnersResponseDto _$PartnersResponseDtoFromJson(Map<String, dynamic> json) =>
    PartnersResponseDto(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => PartnerDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] == null
          ? null
          : PaginationMetaDto.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PartnersResponseDtoToJson(
  PartnersResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'meta': instance.meta,
};

PaginationMetaDto _$PaginationMetaDtoFromJson(Map<String, dynamic> json) =>
    PaginationMetaDto(
      total: _parseInt(json['total']),
      perPage: _parseInt(json['per_page'], 20),
      currentPage: _parseInt(json['current_page'], 1),
      lastPage: _parseInt(json['last_page'], 1),
      from: _parseInt(json['from']),
      to: _parseInt(json['to']),
      hasMore: _parseBool(json['has_more']),
    );

Map<String, dynamic> _$PaginationMetaDtoToJson(PaginationMetaDto instance) =>
    <String, dynamic>{
      'total': instance.total,
      'per_page': instance.perPage,
      'current_page': instance.currentPage,
      'last_page': instance.lastPage,
      'from': instance.from,
      'to': instance.to,
      'has_more': instance.hasMore,
    };

PaginatedPartnersDto _$PaginatedPartnersDtoFromJson(
  Map<String, dynamic> json,
) => PaginatedPartnersDto(
  data: (json['data'] as List<dynamic>)
      .map((e) => PartnerDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  currentPage: _parseInt(json['current_page'], 1),
  lastPage: _parseInt(json['last_page'], 1),
  perPage: _parseInt(json['per_page'], 20),
  total: _parseInt(json['total']),
);

Map<String, dynamic> _$PaginatedPartnersDtoToJson(
  PaginatedPartnersDto instance,
) => <String, dynamic>{
  'data': instance.data,
  'current_page': instance.currentPage,
  'last_page': instance.lastPage,
  'per_page': instance.perPage,
  'total': instance.total,
};

MenuItemDto _$MenuItemDtoFromJson(Map<String, dynamic> json) => MenuItemDto(
  id: _parseInt(json['id']),
  partnerId: _parseInt(json['partner_id']),
  menuCategoryId: json['menu_category_id'] == null
      ? null
      : _parseInt(json['menu_category_id']),
  name: json['name']?.toString() ?? 'Menu Item',
  description: json['description'] as String?,
  imageUrl: json['image_url'] as String?,
  price: _parseDouble(json['price']),
  originalPrice: _parseDoubleNullable(json['original_price']),
  unit: json['unit'] as String?,
  isAvailable: _parseBoolNullable(json['is_available']),
  isPopular: _parseBoolNullable(json['is_popular']),
  isFeatured: _parseBoolNullable(json['is_featured']),
  tags: _parseStringList(json['tags']),
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
      'tags': instance.tags,
    };

MenuCategoryDto _$MenuCategoryDtoFromJson(Map<String, dynamic> json) =>
    MenuCategoryDto(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? 'Menu',
      description: json['description'] as String?,
      availableItems: (json['available_items'] as List<dynamic>?)
          ?.map((e) => MenuItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MenuCategoryDtoToJson(MenuCategoryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'available_items': instance.availableItems,
    };

PartnerMenuResponseDto _$PartnerMenuResponseDtoFromJson(
  Map<String, dynamic> json,
) => PartnerMenuResponseDto(
  success: json['success'] as bool,
  data: PartnerMenuDataDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PartnerMenuResponseDtoToJson(
  PartnerMenuResponseDto instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

PartnerMenuDataDto _$PartnerMenuDataDtoFromJson(Map<String, dynamic> json) =>
    PartnerMenuDataDto(
      partner: PartnerDto.fromJson(json['partner'] as Map<String, dynamic>),
      categories: (json['categories'] as List<dynamic>)
          .map((e) => MenuCategoryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PartnerMenuDataDtoToJson(PartnerMenuDataDto instance) =>
    <String, dynamic>{
      'partner': instance.partner,
      'categories': instance.categories,
    };
