// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequestDto _$RegisterRequestDtoFromJson(Map<String, dynamic> json) =>
    RegisterRequestDto(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      phoneVerificationToken: json['phone_verification_token'] as String?,
      password: json['password'] as String,
      passwordConfirmation: json['password_confirmation'] as String,
      dateOfBirth: json['date_of_birth'] as String?,
      referralCode: json['referral_code'] as String?,
      addressLine1: json['address_line_1'] as String?,
      addressLine2: json['address_line_2'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      city: json['city'] as String?,
      province: json['province'] as String?,
      zipCode: json['zip_code'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      termsAccepted: json['terms_accepted'] as bool,
      privacyAccepted: json['privacy_accepted'] as bool,
      idType: json['id_type'] as String,
      idNumber: json['id_number'] as String,
      role: json['role'] as String?,
    );

Map<String, dynamic> _$RegisterRequestDtoToJson(RegisterRequestDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'phone_verification_token': ?instance.phoneVerificationToken,
      'password': instance.password,
      'password_confirmation': instance.passwordConfirmation,
      'date_of_birth': instance.dateOfBirth,
      'referral_code': instance.referralCode,
      'address_line_1': instance.addressLine1,
      'address_line_2': instance.addressLine2,
      'is_default': instance.isDefault,
      'city': instance.city,
      'province': instance.province,
      'zip_code': instance.zipCode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'terms_accepted': instance.termsAccepted,
      'privacy_accepted': instance.privacyAccepted,
      'id_type': instance.idType,
      'id_number': instance.idNumber,
      'role': instance.role,
    };
