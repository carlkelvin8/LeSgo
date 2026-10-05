// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_user_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateUserRequestDto _$UpdateUserRequestDtoFromJson(
  Map<String, dynamic> json,
) => UpdateUserRequestDto(
  name: json['name'] as String?,
  phone: json['phone_number'] as String?,
  dateOfBirth: json['date_of_birth'] as String?,
  gender: json['gender'] as String?,
  profilePhoto: json['profile_photo_url'] as String?,
  addressLine1: json['address_line1'] as String?,
  addressLine2: json['address_line2'] as String?,
);

Map<String, dynamic> _$UpdateUserRequestDtoToJson(
  UpdateUserRequestDto instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'phone_number': ?instance.phone,
  'date_of_birth': ?instance.dateOfBirth,
  'gender': ?instance.gender,
  'profile_photo_url': ?instance.profilePhoto,
  'address_line1': ?instance.addressLine1,
  'address_line2': ?instance.addressLine2,
};
