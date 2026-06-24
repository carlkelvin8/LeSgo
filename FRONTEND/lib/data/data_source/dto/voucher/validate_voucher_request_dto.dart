import 'package:json_annotation/json_annotation.dart';

part 'validate_voucher_request_dto.g.dart';

@JsonSerializable(includeIfNull: false)
class ValidateVoucherRequestDto {
  @JsonKey(name: 'voucher_code')
  final String voucherCode;
  @JsonKey(name: 'order_value')
  final double orderValue;
  @JsonKey(name: 'service_id')
  final int? serviceId;

  ValidateVoucherRequestDto({
    required this.voucherCode,
    required this.orderValue,
    this.serviceId,
  });

  factory ValidateVoucherRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ValidateVoucherRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ValidateVoucherRequestDtoToJson(this);
}
