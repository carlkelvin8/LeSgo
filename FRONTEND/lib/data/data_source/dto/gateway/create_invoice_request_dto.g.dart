// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_invoice_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateInvoiceRequestDto _$CreateInvoiceRequestDtoFromJson(
  Map<String, dynamic> json,
) => CreateInvoiceRequestDto(
  orderId: (json['order_id'] as num).toInt(),
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String,
  paymentMethod: json['payment_method'] as String,
  customerName: json['customer_name'] as String,
  customerEmail: json['customer_email'] as String,
  customerPhone: json['customer_phone'] as String,
  successRedirectUrl: json['success_redirect_url'] as String,
  failureRedirectUrl: json['failure_redirect_url'] as String,
  description: json['description'] as String,
);

Map<String, dynamic> _$CreateInvoiceRequestDtoToJson(
  CreateInvoiceRequestDto instance,
) => <String, dynamic>{
  'order_id': instance.orderId,
  'amount': instance.amount,
  'currency': instance.currency,
  'payment_method': instance.paymentMethod,
  'customer_name': instance.customerName,
  'customer_email': instance.customerEmail,
  'customer_phone': instance.customerPhone,
  'success_redirect_url': instance.successRedirectUrl,
  'failure_redirect_url': instance.failureRedirectUrl,
  'description': instance.description,
};
