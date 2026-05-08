// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_merchant_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterMerchantRequestDto _$RegisterMerchantRequestDtoFromJson(
        Map<String, dynamic> json) =>
    RegisterMerchantRequestDto(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      password: json['password'] as String,
      passwordConfirmation: json['password_confirmation'] as String,
      role: json['role'] as String? ?? 'partner_admin',
      restaurantName: json['restaurant_name'] as String,
      zipCode: json['zip_code'] as String?,
      selfiePath: json['selfie_path'] as String?,
      validIdPath: json['valid_id_path'] as String?,
      digitalSignaturePath: json['digital_signature_path'] as String?,
      barangayPermitPath: json['barangay_permit_path'] as String?,
      mayorsPermitPath: json['mayors_permit_path'] as String?,
      dtiPermitPath: json['dti_permit_path'] as String?,
    );

Map<String, dynamic> _$RegisterMerchantRequestDtoToJson(
        RegisterMerchantRequestDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'password': instance.password,
      'password_confirmation': instance.passwordConfirmation,
      'role': instance.role,
      'restaurant_name': instance.restaurantName,
      'zip_code': instance.zipCode,
      'selfie_path': instance.selfiePath,
      'valid_id_path': instance.validIdPath,
      'digital_signature_path': instance.digitalSignaturePath,
      'barangay_permit_path': instance.barangayPermitPath,
      'mayors_permit_path': instance.mayorsPermitPath,
      'dti_permit_path': instance.dtiPermitPath,
    };
