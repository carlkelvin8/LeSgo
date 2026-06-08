// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_address_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateAddressRequestDto _$CreateAddressRequestDtoFromJson(
  Map<String, dynamic> json,
) => CreateAddressRequestDto(
  label: json['label'] as String,
  contactName: json['contact_name'] as String,
  contactPhone: json['contact_phone'] as String,
  addressLine1: json['address_line1'] as String,
  addressLine2: json['address_line2'] as String?,
  city: json['city'] as String?,
  region: json['region'] as String?,
  postalCode: json['postal_code'] as String?,
  country: json['country'] as String?,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  isDefault: json['is_default'] == true || json['is_default'] == 1,
);

Map<String, dynamic> _$CreateAddressRequestDtoToJson(
  CreateAddressRequestDto instance,
) => <String, dynamic>{
  'label': instance.label,
  'contact_name': instance.contactName,
  'contact_phone': instance.contactPhone,
  'address_line1': instance.addressLine1,
  if (instance.addressLine2 case final value?) 'address_line2': value,
  if (instance.city case final value?) 'city': value,
  if (instance.region case final value?) 'region': value,
  if (instance.postalCode case final value?) 'postal_code': value,
  if (instance.country case final value?) 'country': value,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'is_default': instance.isDefault,
};
