import 'package:json_annotation/json_annotation.dart';
import 'voucher_dto.dart';

part 'validate_voucher_response_dto.g.dart';

@JsonSerializable()
class ValidateVoucherDataDto {
  final bool valid;
  @JsonKey(name: 'discount_amount')
  final double? discountAmount;
  @JsonKey(name: 'discount_type')
  final String? discountType;
  @JsonKey(name: 'new_total')
  final double? newTotal;
  @JsonKey(name: 'voucher_details')
  final VoucherDetailsDto? voucherDetails;
  final String? error;

  ValidateVoucherDataDto({
    required this.valid,
    this.discountAmount,
    this.discountType,
    this.newTotal,
    this.voucherDetails,
    this.error,
  });

  factory ValidateVoucherDataDto.fromJson(Map<String, dynamic> json) =>
      _$ValidateVoucherDataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ValidateVoucherDataDtoToJson(this);
}

@JsonSerializable()
class ValidateVoucherResponseDto {
  final bool success;
  final String message;
  final ValidateVoucherDataDto data;

  ValidateVoucherResponseDto({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ValidateVoucherResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ValidateVoucherResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ValidateVoucherResponseDtoToJson(this);
}
