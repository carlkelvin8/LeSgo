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

int? _parseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// null = the API did not say (older backend); [] = no service restriction.
List<int>? _parseIntList(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.map(_parseIntNullable).whereType<int>().toList(growable: false);
  }
  return null;
}

/// `applicable_services: null` from the API means "all services", which must
/// stay different from the key being absent (then we fall back to heuristics).
Object? _readApplicableServices(Map<dynamic, dynamic> json, String key) =>
    json.containsKey(key) ? (json[key] ?? const <int>[]) : null;

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
  @JsonKey(name: 'service_id', fromJson: _parseIntNullable)
  final int? serviceId;
  @JsonKey(fromJson: _parseBool)
  final bool eligible;
  @JsonKey(fromJson: _parseBool)
  final bool claimed;

  /// Service ids this voucher works for. Empty = all services; null = unknown.
  @JsonKey(
    name: 'applicable_services',
    readValue: _readApplicableServices,
    fromJson: _parseIntList,
  )
  final List<int>? applicableServices;

  /// Why the voucher is not usable (e.g. "Expired"), when [eligible] is false.
  final String? reason;

  VoucherDto({
    required this.code,
    required this.title,
    this.description,
    this.discountText,
    required this.minOrder,
    this.expiresAt,
    this.serviceId,
    required this.eligible,
    this.claimed = false,
    this.applicableServices,
    this.reason,
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
