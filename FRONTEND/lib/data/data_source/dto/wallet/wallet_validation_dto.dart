import 'package:json_annotation/json_annotation.dart';

part 'wallet_validation_dto.g.dart';

@JsonSerializable()
class WalletValidationDto {
  final bool success;
  @JsonKey(name: 'is_valid')
  final bool isValid;
  @JsonKey(name: 'current_balance')
  final double currentBalance;
  @JsonKey(name: 'minimum_threshold')
  final double minimumThreshold;
  @JsonKey(name: 'needs_topup')
  final bool needsTopup;
  final String? message;

  WalletValidationDto({
    required this.success,
    required this.isValid,
    required this.currentBalance,
    required this.minimumThreshold,
    required this.needsTopup,
    this.message,
  });

  factory WalletValidationDto.fromJson(Map<String, dynamic> json) =>
      _$WalletValidationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WalletValidationDtoToJson(this);
}

@JsonSerializable()
class WalletThresholdDto {
  final bool success;
  @JsonKey(name: 'minimum_threshold')
  final double minimumThreshold;
  @JsonKey(name: 'recommended_topup')
  final double recommendedTopup;

  WalletThresholdDto({
    required this.success,
    required this.minimumThreshold,
    required this.recommendedTopup,
  });

  factory WalletThresholdDto.fromJson(Map<String, dynamic> json) =>
      _$WalletThresholdDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WalletThresholdDtoToJson(this);
}
