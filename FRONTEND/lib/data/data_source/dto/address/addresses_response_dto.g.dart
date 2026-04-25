// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'addresses_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressesResponseDto _$AddressesResponseDtoFromJson(
  Map<String, dynamic> json,
) => AddressesResponseDto(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => AddressDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  error: json['error'] as String?,
);

Map<String, dynamic> _$AddressesResponseDtoToJson(
  AddressesResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
