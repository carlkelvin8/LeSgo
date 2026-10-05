// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponseDto _$LoginResponseDtoFromJson(Map<String, dynamic> json) =>
    LoginResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      token: json['token'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt(),
      user: json['user'] == null
          ? null
          : LoginUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseDtoToJson(LoginResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'token': instance.token,
      'expires_in': instance.expiresIn,
      'user': instance.user,
    };

LoginUserDto _$LoginUserDtoFromJson(Map<String, dynamic> json) => LoginUserDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String,
      driverProfile: json['driver_profile'] as Map<String, dynamic>?,
      partnerId: (json['partner_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LoginUserDtoToJson(LoginUserDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone_number': instance.phoneNumber,
      'role': instance.role,
      'driver_profile': instance.driverProfile,
      'partner_id': instance.partnerId,
    };
