// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressResponseDto _$AddressResponseDtoFromJson(Map<String, dynamic> json) =>
    AddressResponseDto(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : AddressDto.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$AddressResponseDtoToJson(AddressResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'message': instance.message,
      'error': instance.error,
    };
