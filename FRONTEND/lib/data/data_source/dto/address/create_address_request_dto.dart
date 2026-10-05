import 'package:json_annotation/json_annotation.dart';

part 'create_address_request_dto.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateAddressRequestDto {
  final String label;
  @JsonKey(name: 'contact_name')
  final String contactName;
  @JsonKey(name: 'contact_phone')
  final String contactPhone;
  @JsonKey(name: 'address_line1')
  final String addressLine1;
  @JsonKey(name: 'address_line2')
  final String? addressLine2;
  final String? city;
  final String? region;
  @JsonKey(name: 'postal_code')
  final String? postalCode;
  final String? country;
  final double latitude;
  final double longitude;
  @JsonKey(name: 'is_default')
  final bool isDefault;

  CreateAddressRequestDto({
    required this.label,
    required this.contactName,
    required this.contactPhone,
    required this.addressLine1,
    this.addressLine2,
    this.city,
    this.region,
    this.postalCode,
    this.country,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });

  factory CreateAddressRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateAddressRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateAddressRequestDtoToJson(this);
}
