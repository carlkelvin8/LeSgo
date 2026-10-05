import 'package:json_annotation/json_annotation.dart';

part 'invoice_request_dto.g.dart';

@JsonSerializable()
class InvoiceRequestDto {
  final double amount;
  final String description;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'success_url')
  final String? successUrl;
  @JsonKey(name: 'cancel_url')
  final String? cancelUrl;
  final Map<String, dynamic>? metadata;

  InvoiceRequestDto({
    required this.amount,
    required this.description,
    required this.paymentMethod,
    this.successUrl,
    this.cancelUrl,
    this.metadata,
  });

  factory InvoiceRequestDto.fromJson(Map<String, dynamic> json) =>
      _$InvoiceRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceRequestDtoToJson(this);
}
