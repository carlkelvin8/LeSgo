// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BranchDto _$BranchDtoFromJson(Map<String, dynamic> json) => BranchDto(
  id: (json['id'] as num).toInt(),
  partnerId: (json['partner_id'] as num).toInt(),
  name: json['name'] as String,
  address: json['address'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  isOpen: json['is_open'] as bool,
  operatingHours: json['operating_hours'] as String,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$BranchDtoToJson(BranchDto instance) => <String, dynamic>{
  'id': instance.id,
  'partner_id': instance.partnerId,
  'name': instance.name,
  'address': instance.address,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'is_open': instance.isOpen,
  'operating_hours': instance.operatingHours,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
