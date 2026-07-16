import 'package:json_annotation/json_annotation.dart';

part 'invoice_dto.g.dart';

@JsonSerializable()
class InvoiceDto {
  @JsonKey(name: 'invoice_id')
  final String invoiceId;
  @JsonKey(name: 'invoice_url')
  final String? invoiceUrl;
  @JsonKey(name: 'order_id')
  final int? orderId;
  final double amount;
  final String currency;
  final String status;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'paid_at')
  final String? paidAt;
  @JsonKey(name: 'expires_at')
  final String expiresAt;
  final String? provider;

  InvoiceDto({
    required this.invoiceId,
    this.invoiceUrl,
    this.orderId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.paidAt,
    required this.expiresAt,
    this.provider,
  });

  factory InvoiceDto.fromJson(Map<String, dynamic> json) =>
      _$InvoiceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceDtoToJson(this);
}
