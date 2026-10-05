// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_validation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletValidationDto _$WalletValidationDtoFromJson(Map<String, dynamic> json) =>
    WalletValidationDto(
      success: json['success'] as bool,
      isValid: json['is_valid'] as bool,
      currentBalance: (json['current_balance'] as num).toDouble(),
      minimumThreshold: (json['minimum_threshold'] as num).toDouble(),
      needsTopup: json['needs_topup'] as bool,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$WalletValidationDtoToJson(
  WalletValidationDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'is_valid': instance.isValid,
  'current_balance': instance.currentBalance,
  'minimum_threshold': instance.minimumThreshold,
  'needs_topup': instance.needsTopup,
  'message': instance.message,
};

WalletThresholdDto _$WalletThresholdDtoFromJson(Map<String, dynamic> json) =>
    WalletThresholdDto(
      success: json['success'] as bool,
      minimumThreshold: (json['minimum_threshold'] as num).toDouble(),
      recommendedTopup: (json['recommended_topup'] as num).toDouble(),
    );

Map<String, dynamic> _$WalletThresholdDtoToJson(WalletThresholdDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'minimum_threshold': instance.minimumThreshold,
      'recommended_topup': instance.recommendedTopup,
    };
