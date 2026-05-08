// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_merchant_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterMerchantResponseDto _$RegisterMerchantResponseDtoFromJson(
        Map<String, dynamic> json) =>
    RegisterMerchantResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      token: json['token'] as String?,
      user: json['user'] == null
          ? null
          : MerchantUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RegisterMerchantResponseDtoToJson(
        RegisterMerchantResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'token': instance.token,
      'user': instance.user,
    };

MerchantUserDto _$MerchantUserDtoFromJson(Map<String, dynamic> json) =>
    MerchantUserDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String,
      partnerId: (json['partner_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MerchantUserDtoToJson(MerchantUserDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone_number': instance.phoneNumber,
      'role': instance.role,
      'partner_id': instance.partnerId,
    };
