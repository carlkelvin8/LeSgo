import 'package:json_annotation/json_annotation.dart';
import 'invoice_dto.dart';

part 'invoice_response_dto.g.dart';

@JsonSerializable()
class InvoiceResponseDto {
  final bool success;
  final String? message;
  final InvoiceDto data;

  InvoiceResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory InvoiceResponseDto.fromJson(Map<String, dynamic> json) =>
      _$InvoiceResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceResponseDtoToJson(this);
}
