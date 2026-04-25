// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validate_voucher_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidateVoucherDataDto _$ValidateVoucherDataDtoFromJson(
  Map<String, dynamic> json,
) => ValidateVoucherDataDto(
  valid: json['valid'] as bool,
  discountAmount: (json['discount_amount'] as num?)?.toDouble(),
  discountType: json['discount_type'] as String?,
  newTotal: (json['new_total'] as num?)?.toDouble(),
  voucherDetails: json['voucher_details'] == null
      ? null
      : VoucherDetailsDto.fromJson(
          json['voucher_details'] as Map<String, dynamic>,
        ),
  error: json['error'] as String?,
);

Map<String, dynamic> _$ValidateVoucherDataDtoToJson(
  ValidateVoucherDataDto instance,
) => <String, dynamic>{
  'valid': instance.valid,
  'discount_amount': instance.discountAmount,
  'discount_type': instance.discountType,
  'new_total': instance.newTotal,
  'voucher_details': instance.voucherDetails,
  'error': instance.error,
};

ValidateVoucherResponseDto _$ValidateVoucherResponseDtoFromJson(
  Map<String, dynamic> json,
) => ValidateVoucherResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: ValidateVoucherDataDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ValidateVoucherResponseDtoToJson(
  ValidateVoucherResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};
