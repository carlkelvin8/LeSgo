// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refund_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefundRequestDto _$RefundRequestDtoFromJson(Map<String, dynamic> json) =>
    RefundRequestDto(
      paymentId: (json['payment_id'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$RefundRequestDtoToJson(RefundRequestDto instance) =>
    <String, dynamic>{
      'payment_id': instance.paymentId,
      'amount': instance.amount,
      'reason': instance.reason,
    };
