import 'package:json_annotation/json_annotation.dart';
import '../gateway/invoice_dto.dart';

part 'invoice_response_dto.g.dart';

/// Wraps the gateway createInvoice response:
/// { success, message, data: { invoice: {...}, payment_id: int } }
@JsonSerializable()
class InvoiceResponseDto {
  final bool success;
  final String? message;
  final String? error;
  final InvoiceDataDto? data;

  InvoiceResponseDto({
    required this.success,
    this.message,
    this.error,
    this.data,
  });

  factory InvoiceResponseDto.fromJson(Map<String, dynamic> json) =>
      _$InvoiceResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceResponseDtoToJson(this);
}

@JsonSerializable()
class InvoiceDataDto {
  final InvoiceDto? invoice;
  @JsonKey(name: 'payment_id')
  final int? paymentId;

  InvoiceDataDto({
    this.invoice,
    this.paymentId,
  });

  factory InvoiceDataDto.fromJson(Map<String, dynamic> json) =>
      _$InvoiceDataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceDataDtoToJson(this);
}
