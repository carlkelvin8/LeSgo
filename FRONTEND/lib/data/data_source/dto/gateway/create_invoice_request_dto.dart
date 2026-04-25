import 'package:json_annotation/json_annotation.dart';

part 'create_invoice_request_dto.g.dart';

@JsonSerializable()
class CreateInvoiceRequestDto {
  @JsonKey(name: 'order_id')
  final int orderId;
  final double amount;
  final String currency;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'customer_name')
  final String customerName;
  @JsonKey(name: 'customer_email')
  final String customerEmail;
  @JsonKey(name: 'customer_phone')
  final String customerPhone;
  @JsonKey(name: 'success_redirect_url')
  final String successRedirectUrl;
  @JsonKey(name: 'failure_redirect_url')
  final String failureRedirectUrl;
  final String description;

  CreateInvoiceRequestDto({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.successRedirectUrl,
    required this.failureRedirectUrl,
    required this.description,
  });

  factory CreateInvoiceRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateInvoiceRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateInvoiceRequestDtoToJson(this);
}
