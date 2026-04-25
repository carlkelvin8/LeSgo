// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvoiceDto _$InvoiceDtoFromJson(Map<String, dynamic> json) => InvoiceDto(
  invoiceId: json['invoice_id'] as String,
  invoiceUrl: json['invoice_url'] as String?,
  orderId: (json['order_id'] as num?)?.toInt(),
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String,
  status: json['status'] as String,
  paymentMethod: json['payment_method'] as String,
  paidAt: json['paid_at'] as String?,
  expiresAt: json['expires_at'] as String,
);

Map<String, dynamic> _$InvoiceDtoToJson(InvoiceDto instance) =>
    <String, dynamic>{
      'invoice_id': instance.invoiceId,
      'invoice_url': instance.invoiceUrl,
      'order_id': instance.orderId,
      'amount': instance.amount,
      'currency': instance.currency,
      'status': instance.status,
      'payment_method': instance.paymentMethod,
      'paid_at': instance.paidAt,
      'expires_at': instance.expiresAt,
    };
