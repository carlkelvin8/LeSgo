import 'package:json_annotation/json_annotation.dart';

part 'refund_request_dto.g.dart';

@JsonSerializable()
class RefundRequestDto {
  @JsonKey(name: 'payment_id')
  final int paymentId;
  final double amount;
  final String reason;

  RefundRequestDto({
    required this.paymentId,
    required this.amount,
    required this.reason,
  });

  factory RefundRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RefundRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RefundRequestDtoToJson(this);
}
