import 'package:json_annotation/json_annotation.dart';

part 'refund_response_dto.g.dart';

@JsonSerializable()
class RefundDataDto {
  @JsonKey(name: 'refund_id')
  final String refundId;
  @JsonKey(name: 'payment_id')
  final int paymentId;
  final double amount;
  final String status;
  @JsonKey(name: 'refunded_at')
  final String refundedAt;

  RefundDataDto({
    required this.refundId,
    required this.paymentId,
    required this.amount,
    required this.status,
    required this.refundedAt,
  });

  factory RefundDataDto.fromJson(Map<String, dynamic> json) =>
      _$RefundDataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RefundDataDtoToJson(this);
}

@JsonSerializable()
class RefundResponseDto {
  final bool success;
  final String message;
  final RefundDataDto data;

  RefundResponseDto({
    required this.success,
    required this.message,
    required this.data,
  });

  factory RefundResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RefundResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RefundResponseDtoToJson(this);
}
