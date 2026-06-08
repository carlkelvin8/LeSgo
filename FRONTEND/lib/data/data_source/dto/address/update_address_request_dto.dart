import 'package:json_annotation/json_annotation.dart';

part 'update_address_request_dto.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateAddressRequestDto {
  final String? label;
  @JsonKey(name: 'contact_name')
  final String? contactName;
  @JsonKey(name: 'contact_phone')
  final String? contactPhone;
  @JsonKey(name: 'address_line1')
  final String? addressLine1;
  @JsonKey(name: 'address_line2')
  final String? addressLine2;
  final String? city;
  final String? region;
  @JsonKey(name: 'postal_code')
  final String? postalCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'is_default')
  final bool? isDefault;

  UpdateAddressRequestDto({
    this.label,
    this.contactName,
    this.contactPhone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.region,
    this.postalCode,
    this.country,
    this.latitude,
    this.longitude,
    this.isDefault,
  });

  factory UpdateAddressRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateAddressRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateAddressRequestDtoToJson(this);
}
