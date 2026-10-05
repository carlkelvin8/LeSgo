// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceDto _$ServiceDtoFromJson(Map<String, dynamic> json) => ServiceDto(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  code: json['code'] as String,
  description: json['description'] as String,
  baseFare: (json['base_fare'] as num).toDouble(),
  perKmRate: (json['per_km_rate'] as num).toDouble(),
  minimumFare: (json['minimum_fare'] as num).toDouble(),
  iconUrl: json['icon_url'] as String?,
  isActive: json['is_active'] as bool,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$ServiceDtoToJson(ServiceDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'description': instance.description,
      'base_fare': instance.baseFare,
      'per_km_rate': instance.perKmRate,
      'minimum_fare': instance.minimumFare,
      'icon_url': instance.iconUrl,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
