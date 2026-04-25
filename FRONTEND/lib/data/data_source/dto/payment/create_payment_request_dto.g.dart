// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_payment_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePaymentRequestDto _$CreatePaymentRequestDtoFromJson(
  Map<String, dynamic> json,
) => CreatePaymentRequestDto(
  orderId: (json['order_id'] as num).toInt(),
  customerId: (json['customer_id'] as num).toInt(),
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String? ?? 'PHP',
  method: json['method'] as String,
  status: json['status'] as String? ?? 'pending',
  provider: json['provider'] as String?,
  providerReference: json['provider_reference'] as String?,
  meta: json['meta'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$CreatePaymentRequestDtoToJson(
  CreatePaymentRequestDto instance,
) => <String, dynamic>{
  'order_id': instance.orderId,
  'customer_id': instance.customerId,
  'amount': instance.amount,
  'currency': instance.currency,
  'method': instance.method,
  'status': instance.status,
  'provider': instance.provider,
  'provider_reference': instance.providerReference,
  'meta': instance.meta,
};
