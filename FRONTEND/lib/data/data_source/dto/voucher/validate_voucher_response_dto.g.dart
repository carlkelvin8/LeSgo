// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validate_voucher_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidateVoucherResponseDto _$ValidateVoucherResponseDtoFromJson(
  Map<String, dynamic> json,
) => ValidateVoucherResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: _validateVoucherDataFromJson(json['data']),
);

Map<String, dynamic> _$ValidateVoucherResponseDtoToJson(
  ValidateVoucherResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
};
