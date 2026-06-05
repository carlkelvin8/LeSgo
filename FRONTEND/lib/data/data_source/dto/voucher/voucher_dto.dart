import 'package:json_annotation/json_annotation.dart';

part 'voucher_dto.g.dart';

double _parseMoney(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
  return 0;
}

double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool _parseBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

@JsonSerializable()
class VoucherDto {
  final String code;
  final String title;
  final String? description;
  @JsonKey(name: 'discount_text')
  final String? discountText;
  @JsonKey(name: 'min_order', fromJson: _parseMoney)
  final double minOrder;
  @JsonKey(name: 'expires_at')
  final String? expiresAt;
  @JsonKey(fromJson: _parseBool)
  final bool eligible;
  @JsonKey(fromJson: _parseBool)
  final bool claimed;

  VoucherDto({
    required this.code,
    required this.title,
    this.description,
    this.discountText,
    required this.minOrder,
    this.expiresAt,
    required this.eligible,
    this.claimed = false,
  });

  factory VoucherDto.fromJson(Map<String, dynamic> json) =>
      _$VoucherDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VoucherDtoToJson(this);
}

@JsonSerializable(createFactory: false, createToJson: false)
class VoucherDetailsDto {
  final String code;
  final String title;
  @JsonKey(name: 'discount_value')
  final double? discountValue;
  @JsonKey(name: 'min_order_value')
  final double? minOrderValue;
  @JsonKey(name: 'max_discount')
  final double? maxDiscount;
  @JsonKey(name: 'expires_at')
  final String? expiresAt;

  VoucherDetailsDto({
    required this.code,
    required this.title,
    this.discountValue,
    this.minOrderValue,
    this.maxDiscount,
    this.expiresAt,
  });

  factory VoucherDetailsDto.fromJson(Map<String, dynamic> json) {
    return VoucherDetailsDto(
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? json['code']?.toString() ?? '',
      discountValue: _parseDoubleNullable(json['discount_value'] ?? json['value']),
      minOrderValue: _parseDoubleNullable(json['min_order_value']),
      maxDiscount: _parseDoubleNullable(json['max_discount']),
      expiresAt: json['expires_at'] as String?,
    );
  }
}
