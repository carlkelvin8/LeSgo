// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressDto _$AddressDtoFromJson(Map<String, dynamic> json) => AddressDto(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  label: json['label'] as String,
  contactName: json['contact_name'] as String,
  contactPhone: json['contact_phone'] as String,
  addressLine1: json['address_line1'] as String,
  addressLine2: json['address_line2'] as String?,
  country: json['country'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  isDefault: json['is_default'] as bool,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$AddressDtoToJson(AddressDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'label': instance.label,
      'contact_name': instance.contactName,
      'contact_phone': instance.contactPhone,
      'address_line1': instance.addressLine1,
      'address_line2': instance.addressLine2,
      'country': instance.country,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'is_default': instance.isDefault,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
