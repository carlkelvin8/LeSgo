import 'package:json_annotation/json_annotation.dart';

part 'voucher_dto.g.dart';

@JsonSerializable()
class VoucherDto {
  final String code;
  final String title;
  final String description;
  @JsonKey(name: 'discount_text')
  final String discountText;
  @JsonKey(name: 'min_order')
  final double minOrder;
  @JsonKey(name: 'expires_at')
  final String expiresAt;
  final bool eligible;

  VoucherDto({
    required this.code,
    required this.title,
    required this.description,
    required this.discountText,
    required this.minOrder,
    required this.expiresAt,
    required this.eligible,
  });

  factory VoucherDto.fromJson(Map<String, dynamic> json) =>
      _$VoucherDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VoucherDtoToJson(this);
}

@JsonSerializable()
class VoucherDetailsDto {
  final String code;
  final String title;
  @JsonKey(name: 'discount_value')
  final double discountValue;
  @JsonKey(name: 'min_order_value')
  final double minOrderValue;
  @JsonKey(name: 'max_discount')
  final double maxDiscount;
  @JsonKey(name: 'expires_at')
  final String expiresAt;

  VoucherDetailsDto({
    required this.code,
    required this.title,
    required this.discountValue,
    required this.minOrderValue,
    required this.maxDiscount,
    required this.expiresAt,
  });

  factory VoucherDetailsDto.fromJson(Map<String, dynamic> json) =>
      _$VoucherDetailsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VoucherDetailsDtoToJson(this);
}
