// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_branch_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateBranchRequestDto _$UpdateBranchRequestDtoFromJson(
  Map<String, dynamic> json,
) => UpdateBranchRequestDto(
  name: json['name'] as String?,
  address: json['address'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  isOpen: json['is_open'] as bool?,
  operatingHours: json['operating_hours'] as String?,
);

Map<String, dynamic> _$UpdateBranchRequestDtoToJson(
  UpdateBranchRequestDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'address': instance.address,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'is_open': instance.isOpen,
  'operating_hours': instance.operatingHours,
};
