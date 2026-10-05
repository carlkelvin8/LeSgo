import 'package:json_annotation/json_annotation.dart';

part 'partner_dto.g.dart';

@JsonSerializable()
class SharedPartnerDto {
  final int? id;
  final String? name;
  final String? description;
  final String? logo;
  @JsonKey(name: 'cover_image')
  final String? coverImage;
  final String? address;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  final String? email;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'is_open')
  final bool? isOpen;
  final double? rating;
  @JsonKey(name: 'total_reviews')
  final int? totalReviews;
  @JsonKey(name: 'delivery_fee')
  final double? deliveryFee;
  @JsonKey(name: 'estimated_delivery_time')
  final String? estimatedDeliveryTime;
  @JsonKey(name: 'service_type')
  final String? serviceType;

  const SharedPartnerDto({
    this.id,
    this.name,
    this.description,
    this.logo,
    this.coverImage,
    this.address,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.email,
    this.isActive,
    this.isOpen,
    this.rating,
    this.totalReviews,
    this.deliveryFee,
    this.estimatedDeliveryTime,
    this.serviceType,
  });

  factory SharedPartnerDto.fromJson(Map<String, dynamic> json) =>
      _$SharedPartnerDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SharedPartnerDtoToJson(this);
}
