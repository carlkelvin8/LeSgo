import 'package:json_annotation/json_annotation.dart';

part 'estimate_response_dto.g.dart';

@JsonSerializable()
class FareEstimateDto {
  @JsonKey(name: 'estimated_fare')
  final double estimatedFare;
  @JsonKey(name: 'distance_km')
  final double distanceKm;
  @JsonKey(name: 'base_fare')
  final double baseFare;
  @JsonKey(name: 'per_km_rate')
  final double perKmRate;
  final String currency;

  FareEstimateDto({
    required this.estimatedFare,
    required this.distanceKm,
    required this.baseFare,
    required this.perKmRate,
    required this.currency,
  });

  factory FareEstimateDto.fromJson(Map<String, dynamic> json) =>
      _$FareEstimateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FareEstimateDtoToJson(this);
}

@JsonSerializable()
class EstimateResponseDto {
  final bool success;
  final FareEstimateDto? data;
  final String? error;

  EstimateResponseDto({
    required this.success,
    this.data,
    this.error,
  });

  factory EstimateResponseDto.fromJson(Map<String, dynamic> json) =>
      _$EstimateResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EstimateResponseDtoToJson(this);

  factory EstimateResponseDto.withError(String errorMessage) {
    return EstimateResponseDto(
      success: false,
      data: null,
      error: errorMessage,
    );
  }
}
