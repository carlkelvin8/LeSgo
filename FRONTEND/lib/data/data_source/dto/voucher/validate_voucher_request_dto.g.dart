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
  serviceId: (json['service_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$ValidateVoucherRequestDtoToJson(
  ValidateVoucherRequestDto instance,
) => <String, dynamic>{
  'voucher_code': instance.voucherCode,
  'order_value': instance.orderValue,
  if (instance.serviceId case final value?) 'service_id': value,
};
