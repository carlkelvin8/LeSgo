// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_driver_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterDriverRequestDto _$RegisterDriverRequestDtoFromJson(
        Map<String, dynamic> json) =>
    RegisterDriverRequestDto(
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
      password: json['password'] as String,
      passwordConfirmation: json['password_confirmation'] as String,
      licenseNumber: json['license_number'] as String,
      licenseExpiryDate: json['license_expiry_date'] as String?,
      lastLatitude: (json['last_latitude'] as num?)?.toDouble(),
      lastLongitude: (json['last_longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$RegisterDriverRequestDtoToJson(
        RegisterDriverRequestDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'phone_number': instance.phoneNumber,
      'password': instance.password,
      'password_confirmation': instance.passwordConfirmation,
      'license_number': instance.licenseNumber,
      'license_expiry_date': instance.licenseExpiryDate,
      'last_latitude': instance.lastLatitude,
      'last_longitude': instance.lastLongitude,
    };
