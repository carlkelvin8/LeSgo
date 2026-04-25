// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validate_voucher_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidateVoucherRequestDto _$ValidateVoucherRequestDtoFromJson(
  Map<String, dynamic> json,
) => ValidateVoucherRequestDto(
  voucherCode: json['voucher_code'] as String,
  orderValue: (json['order_value'] as num).toDouble(),
);

Map<String, dynamic> _$ValidateVoucherRequestDtoToJson(
  ValidateVoucherRequestDto instance,
) => <String, dynamic>{
  'voucher_code': instance.voucherCode,
  'order_value': instance.orderValue,
};
