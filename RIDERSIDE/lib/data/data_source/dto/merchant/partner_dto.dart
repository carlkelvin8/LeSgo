import 'package:json_annotation/json_annotation.dart';

part 'partner_dto.g.dart';

@JsonSerializable()
class PartnerDto {
  final int id;
  final String name;
  @JsonKey(name: 'legal_name')
  final String? legalName;
  final String? slug;
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
  @JsonKey(name: 'accepts_online_payment')
  final bool? acceptsOnlinePayment;
  @JsonKey(name: 'opening_hours')
  final Map<String, dynamic>? openingHours;
  @JsonKey(name: 'support_phone')
  final String? supportPhone;
  @JsonKey(name: 'support_email')
  final String? supportEmail;
  @JsonKey(name: 'referral_code')
  final String? referralCode;
  
  PartnerDto({
    required this.id,
    required this.name,
    this.legalName,
    this.slug,
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
    this.acceptsOnlinePayment,
    this.openingHours,
    this.supportPhone,
    this.supportEmail,
    this.referralCode,
  });
  
  factory PartnerDto.fromJson(Map<String, dynamic> json) => 
      _$PartnerDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PartnerDtoToJson(this);
}
