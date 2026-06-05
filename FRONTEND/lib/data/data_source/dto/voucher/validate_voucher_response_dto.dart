import 'package:json_annotation/json_annotation.dart';
import 'voucher_dto.dart';

part 'validate_voucher_response_dto.g.dart';

double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

ValidateVoucherDataDto _validateVoucherDataFromJson(Object? json) {
  return ValidateVoucherDataDto.fromJson(json as Map<String, dynamic>);
}

@JsonSerializable(createFactory: false, createToJson: false)
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

  factory ValidateVoucherDataDto.fromJson(Map<String, dynamic> json) {
    VoucherDetailsDto? details;
    final rawDetails = json['voucher_details'];
    if (rawDetails is Map<String, dynamic>) {
      try {
        details = VoucherDetailsDto.fromJson(rawDetails);
      } catch (_) {
        details = null;
      }
    }

    return ValidateVoucherDataDto(
      valid: json['valid'] as bool? ?? false,
      discountAmount: _parseDoubleNullable(json['discount_amount']),
      discountType: json['discount_type'] as String?,
      newTotal: _parseDoubleNullable(json['new_total']),
      voucherDetails: details,
      error: json['error'] as String?,
    );
  }
}

@JsonSerializable()
class ValidateVoucherResponseDto {
  final bool success;
  final String message;
  @JsonKey(fromJson: _validateVoucherDataFromJson, includeToJson: false)
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
