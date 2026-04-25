import 'package:json_annotation/json_annotation.dart';

part 'validate_voucher_request_dto.g.dart';

@JsonSerializable()
class ValidateVoucherRequestDto {
  @JsonKey(name: 'voucher_code')
  final String voucherCode;
  @JsonKey(name: 'order_value')
  final double orderValue;

  ValidateVoucherRequestDto({
    required this.voucherCode,
    required this.orderValue,
  });

  factory ValidateVoucherRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ValidateVoucherRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ValidateVoucherRequestDtoToJson(this);
}
