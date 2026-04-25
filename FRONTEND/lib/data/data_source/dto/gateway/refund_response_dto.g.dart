// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refund_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefundDataDto _$RefundDataDtoFromJson(Map<String, dynamic> json) =>
    RefundDataDto(
      refundId: json['refund_id'] as String,
      paymentId: (json['payment_id'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      refundedAt: json['refunded_at'] as String,
    );

Map<String, dynamic> _$RefundDataDtoToJson(RefundDataDto instance) =>
    <String, dynamic>{
      'refund_id': instance.refundId,
      'payment_id': instance.paymentId,
      'amount': instance.amount,
      'status': instance.status,
      'refunded_at': instance.refundedAt,
    };

RefundResponseDto _$RefundResponseDtoFromJson(Map<String, dynamic> json) =>
    RefundResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: RefundDataDto.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RefundResponseDtoToJson(RefundResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };
