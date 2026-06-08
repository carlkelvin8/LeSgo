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
  if (instance.label case final value?) 'label': value,
  if (instance.contactName case final value?) 'contact_name': value,
  if (instance.contactPhone case final value?) 'contact_phone': value,
  if (instance.addressLine1 case final value?) 'address_line1': value,
  if (instance.addressLine2 case final value?) 'address_line2': value,
  if (instance.city case final value?) 'city': value,
  if (instance.region case final value?) 'region': value,
  if (instance.postalCode case final value?) 'postal_code': value,
  if (instance.country case final value?) 'country': value,
  if (instance.latitude case final value?) 'latitude': value,
  if (instance.longitude case final value?) 'longitude': value,
  if (instance.isDefault case final value?) 'is_default': value,
};
