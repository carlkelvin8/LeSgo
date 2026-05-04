// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PartnerDto _$PartnerDtoFromJson(Map<String, dynamic> json) => PartnerDto(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  legalName: json['legal_name'] as String?,
  slug: json['slug'] as String?,
  logoUrl: json['logo_url'] as String?,
  coverImageUrl: json['cover_image_url'] as String?,
  description: json['description'] as String?,
  category: json['category'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  cuisineTypes: (json['cuisine_types'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  rating: (json['rating'] as num?)?.toDouble(),
  totalReviews: (json['total_reviews'] as num?)?.toInt(),
  deliveryFee: (json['delivery_fee'] as num?)?.toDouble(),
  minOrderAmount: (json['min_order_amount'] as num?)?.toInt(),
  estimatedDeliveryMinutes: (json['estimated_delivery_minutes'] as num?)
      ?.toInt(),
  isOpen: json['is_open'] as bool?,
  isFeatured: json['is_featured'] as bool?,
  status: json['status'] as String?,
  acceptsOnlinePayment: json['accepts_online_payment'] as bool?,
  openingHours: json['opening_hours'] as Map<String, dynamic>?,
  supportPhone: json['support_phone'] as String?,
  supportEmail: json['support_email'] as String?,
  referralCode: json['referral_code'] as String?,
);

Map<String, dynamic> _$PartnerDtoToJson(PartnerDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'legal_name': instance.legalName,
      'slug': instance.slug,
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
      'accepts_online_payment': instance.acceptsOnlinePayment,
      'opening_hours': instance.openingHours,
      'support_phone': instance.supportPhone,
      'support_email': instance.supportEmail,
      'referral_code': instance.referralCode,
    };
