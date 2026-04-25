// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceResponseDto _$ServiceResponseDtoFromJson(Map<String, dynamic> json) =>
    ServiceResponseDto(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : ServiceDto.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$ServiceResponseDtoToJson(ServiceResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };
