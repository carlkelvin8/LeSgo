// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvoiceRequestDto _$InvoiceRequestDtoFromJson(Map<String, dynamic> json) =>
    InvoiceRequestDto(
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      paymentMethod: json['payment_method'] as String,
      successUrl: json['success_url'] as String?,
      cancelUrl: json['cancel_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$InvoiceRequestDtoToJson(InvoiceRequestDto instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'description': instance.description,
      'payment_method': instance.paymentMethod,
      'success_url': instance.successUrl,
      'cancel_url': instance.cancelUrl,
      'metadata': instance.metadata,
    };
