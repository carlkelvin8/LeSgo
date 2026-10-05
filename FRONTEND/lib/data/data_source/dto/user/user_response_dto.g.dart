// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserResponseDto _$UserResponseDtoFromJson(Map<String, dynamic> json) =>
    UserResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['user'] == null
          ? null
          : UserProfileDto.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserResponseDtoToJson(UserResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'user': instance.data,
    };
