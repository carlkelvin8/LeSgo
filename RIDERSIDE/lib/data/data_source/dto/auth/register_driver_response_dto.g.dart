// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_driver_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterDriverResponseDto _$RegisterDriverResponseDtoFromJson(
        Map<String, dynamic> json) =>
    RegisterDriverResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      token: json['token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt(),
      data: json['data'] == null
          ? null
          : RegisterDriverDataDto.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RegisterDriverResponseDtoToJson(
        RegisterDriverResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'token': instance.token,
      'refresh_token': instance.refreshToken,
      'expires_in': instance.expiresIn,
      'data': instance.data,
    };

RegisterDriverDataDto _$RegisterDriverDataDtoFromJson(
        Map<String, dynamic> json) =>
    RegisterDriverDataDto(
      user: json['user'] == null
          ? null
          : UserDto.fromJson(json['user'] as Map<String, dynamic>),
      driverProfile: json['driver_profile'] == null
          ? null
          : DriverProfileDto.fromJson(
              json['driver_profile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RegisterDriverDataDtoToJson(
        RegisterDriverDataDto instance) =>
    <String, dynamic>{
      'user': instance.user,
      'driver_profile': instance.driverProfile,
    };

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String,
    );

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone_number': instance.phoneNumber,
      'role': instance.role,
    };

DriverProfileDto _$DriverProfileDtoFromJson(Map<String, dynamic> json) =>
    DriverProfileDto(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      status: json['status'] as String,
      licenseNumber: json['license_number'] as String?,
      rating: (json['rating'] as num).toDouble(),
      totalTrips: (json['total_trips'] as num).toInt(),
    );

Map<String, dynamic> _$DriverProfileDtoToJson(DriverProfileDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'status': instance.status,
      'license_number': instance.licenseNumber,
      'rating': instance.rating,
      'total_trips': instance.totalTrips,
    };
