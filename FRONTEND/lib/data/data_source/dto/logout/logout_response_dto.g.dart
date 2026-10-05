// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logout_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogoutResponseDto _$LogoutResponseDtoFromJson(Map<String, dynamic> json) =>
    LogoutResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$LogoutResponseDtoToJson(LogoutResponseDto instance) =>
    <String, dynamic>{'success': instance.success, 'message': instance.message};
