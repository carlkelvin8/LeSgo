// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  user: json['user'] == null
      ? null
      : UserPayloadDto.fromJson(json['user'] as Map<String, dynamic>),
  token: json['token'] as String?,
  refreshToken: json['refresh_token'] as String?,
  message: json['message'] as String?,
  success: json['success'] as bool?,
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'user': instance.user?.toJson(),
  'token': instance.token,
  'refresh_token': instance.refreshToken,
  'message': instance.message,
  'success': instance.success,
};

UserPayloadDto _$UserPayloadDtoFromJson(Map<String, dynamic> json) =>
    UserPayloadDto(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$UserPayloadDtoToJson(UserPayloadDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
    };
