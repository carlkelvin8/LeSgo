import 'package:json_annotation/json_annotation.dart';

part 'wallet_dto.g.dart';

int _parseInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _parseDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

@JsonSerializable()
class WalletDto {
  @JsonKey(fromJson: _parseInt)
  final int id;
  @JsonKey(name: 'user_id', fromJson: _parseInt)
  final int userId;
  @JsonKey(fromJson: _parseDouble)
  final double balance;
  final String currency;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  WalletDto({
    required this.id,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletDto.fromJson(Map<String, dynamic> json) =>
      _$WalletDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WalletDtoToJson(this);
}

@JsonSerializable()
class WalletResponseDto {
  final bool success;
  final WalletDto? data;
  final String? error;

  WalletResponseDto({
    required this.success,
    this.data,
    this.error,
  });

  factory WalletResponseDto.fromJson(Map<String, dynamic> json) =>
      _$WalletResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WalletResponseDtoToJson(this);

  factory WalletResponseDto.withError(String errorMessage) {
    return WalletResponseDto(
      success: false,
      data: null,
      error: errorMessage,
    );
  }
}

@JsonSerializable()
class WalletTransactionDto {
  @JsonKey(fromJson: _parseInt)
  final int id;
  @JsonKey(name: 'wallet_id', fromJson: _parseInt)
  final int walletId;
  final String type;
  @JsonKey(fromJson: _parseDouble)
  final double amount;
  final String? description;
  final String? reference;
  /// Optional API status: pending, paid, failed, refunded
  final String? status;
  @JsonKey(name: 'created_at')
  final String createdAt;

  WalletTransactionDto({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    this.description,
    this.reference,
    this.status,
    required this.createdAt,
  });

  factory WalletTransactionDto.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTransactionDtoToJson(this);
}

@JsonSerializable()
class WalletTransactionsResponseDto {
  final bool success;
  final List<WalletTransactionDto> data;
  final String? error;

  WalletTransactionsResponseDto({
    required this.success,
    required this.data,
    this.error,
  });

  factory WalletTransactionsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTransactionsResponseDtoToJson(this);

  factory WalletTransactionsResponseDto.withError(String errorMessage) {
    return WalletTransactionsResponseDto(
      success: false,
      data: [],
      error: errorMessage,
    );
  }
}
