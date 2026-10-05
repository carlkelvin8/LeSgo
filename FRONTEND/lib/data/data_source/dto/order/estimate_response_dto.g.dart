// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'estimate_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FareEstimateDto _$FareEstimateDtoFromJson(Map<String, dynamic> json) =>
    FareEstimateDto(
      estimatedFare: (json['estimated_fare'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num).toDouble(),
      baseFare: (json['base_fare'] as num).toDouble(),
      perKmRate: (json['per_km_rate'] as num).toDouble(),
      currency: json['currency'] as String,
    );

Map<String, dynamic> _$FareEstimateDtoToJson(FareEstimateDto instance) =>
    <String, dynamic>{
      'estimated_fare': instance.estimatedFare,
      'distance_km': instance.distanceKm,
      'base_fare': instance.baseFare,
      'per_km_rate': instance.perKmRate,
      'currency': instance.currency,
    };

EstimateResponseDto _$EstimateResponseDtoFromJson(Map<String, dynamic> json) =>
    EstimateResponseDto(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : FareEstimateDto.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$EstimateResponseDtoToJson(
  EstimateResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
