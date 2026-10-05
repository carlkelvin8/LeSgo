// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_branch_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateBranchRequestDto _$CreateBranchRequestDtoFromJson(
  Map<String, dynamic> json,
) => CreateBranchRequestDto(
  name: json['name'] as String,
  address: json['address'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  isOpen: json['is_open'] as bool,
  operatingHours: json['operating_hours'] as String,
);

Map<String, dynamic> _$CreateBranchRequestDtoToJson(
  CreateBranchRequestDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'address': instance.address,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'is_open': instance.isOpen,
  'operating_hours': instance.operatingHours,
};
