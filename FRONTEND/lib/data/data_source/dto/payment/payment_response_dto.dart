import 'package:json_annotation/json_annotation.dart';
import 'payment_dto.dart';

part 'payment_response_dto.g.dart';

@JsonSerializable()
class PaymentResponseDto {
  final bool success;
  final String? message;
  final String? error;
  final PaymentDto? data;

  PaymentResponseDto({
    required this.success,
    this.message,
    this.error,
    this.data,
  });

  factory PaymentResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentResponseDtoToJson(this);
}
