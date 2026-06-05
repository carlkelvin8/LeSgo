// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileDto _$UserProfileDtoFromJson(Map<String, dynamic> json) =>
    UserProfileDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone_number'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      addressLine1: json['address_line1'] as String?,
      addressLine2: json['address_line2'] as String?,
      profilePhoto: json['profile_photo_url'] as String?,
      profilePicture: json['profile_picture'] as String?,
      referralCode: json['referral_code'] as String?,
      referredBy: json['referred_by'] as String?,
      points: (json['points'] as num?)?.toInt(),
      role: json['role'] as String,
      emailVerifiedAt: json['email_verified_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$UserProfileDtoToJson(UserProfileDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone_number': instance.phone,
      'date_of_birth': instance.dateOfBirth,
      'address_line1': instance.addressLine1,
      'address_line2': instance.addressLine2,
      'profile_photo_url': instance.profilePhoto,
      'referral_code': instance.referralCode,
      'referred_by': instance.referredBy,
      'points': instance.points,
      'role': instance.role,
      'email_verified_at': instance.emailVerifiedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
