// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_address_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateAddressRequestDto _$UpdateAddressRequestDtoFromJson(
  Map<String, dynamic> json,
) => UpdateAddressRequestDto(
  label: json['label'] as String?,
  contactName: json['contact_name'] as String?,
  contactPhone: json['contact_phone'] as String?,
  addressLine1: json['address_line1'] as String?,
  addressLine2: json['address_line2'] as String?,
  city: json['city'] as String?,
  region: json['region'] as String?,
  postalCode: json['postal_code'] as String?,
  country: json['country'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  isDefault: json['is_default'] as bool?,
);

Map<String, dynamic> _$UpdateAddressRequestDtoToJson(
  UpdateAddressRequestDto instance,
) => <String, dynamic>{
  'label': ?instance.label,
  'contact_name': ?instance.contactName,
  'contact_phone': ?instance.contactPhone,
  'address_line1': ?instance.addressLine1,
  'address_line2': ?instance.addressLine2,
  'city': ?instance.city,
  'region': ?instance.region,
  'postal_code': ?instance.postalCode,
  'country': ?instance.country,
  'latitude': ?instance.latitude,
  'longitude': ?instance.longitude,
  'is_default': ?instance.isDefault,
};
