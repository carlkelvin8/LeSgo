import 'package:json_annotation/json_annotation.dart';

part 'address_dto.g.dart';

@JsonSerializable()
class AddressDto {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String label;
  @JsonKey(name: 'contact_name')
  final String? contactName;
  @JsonKey(name: 'contact_phone')
  final String? contactPhone;
  @JsonKey(name: 'address_line1')
  final String addressLine1;
  @JsonKey(name: 'address_line2')
  final String? addressLine2;
  final String country;
  final double latitude;
  final double longitude;
  @JsonKey(name: 'is_default')
  final bool isDefault;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  AddressDto({
    required this.id,
    required this.userId,
    required this.label,
    this.contactName,
    this.contactPhone,
    required this.addressLine1,
    this.addressLine2,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AddressDto.fromJson(Map<String, dynamic> json) =>
      _$AddressDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AddressDtoToJson(this);
}
