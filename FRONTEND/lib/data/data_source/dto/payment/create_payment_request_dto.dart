import 'package:json_annotation/json_annotation.dart';

part 'create_payment_request_dto.g.dart';

@JsonSerializable()
class CreatePaymentRequestDto {
  @JsonKey(name: 'order_id')
  final int orderId;
  @JsonKey(name: 'customer_id')
  final int customerId;
  final double amount;
  final String? currency;
  final String method;
  final String? status;
  final String? provider;
  @JsonKey(name: 'provider_reference')
  final String? providerReference;
  final Map<String, dynamic>? meta;

  CreatePaymentRequestDto({
    required this.orderId,
    required this.customerId,
    required this.amount,
    this.currency = 'PHP',
    required this.method,
    this.status = 'pending',
    this.provider,
    this.providerReference,
    this.meta,
  });

  factory CreatePaymentRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreatePaymentRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePaymentRequestDtoToJson(this);
}
