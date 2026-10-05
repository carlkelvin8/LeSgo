// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PartnerResponseDto _$PartnerResponseDtoFromJson(Map<String, dynamic> json) =>
    PartnerResponseDto(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : PartnerDto.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$PartnerResponseDtoToJson(PartnerResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'message': instance.message,
      'error': instance.error,
    };
