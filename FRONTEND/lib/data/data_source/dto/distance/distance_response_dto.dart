import 'package:json_annotation/json_annotation.dart';
import 'distance_dto.dart';

part 'distance_response_dto.g.dart';

@JsonSerializable()
class DistanceCalculationResponseDto {
  final bool success;
  final String? message;
  final DistanceCalculationDto data;

  DistanceCalculationResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory DistanceCalculationResponseDto.fromJson(Map<String, dynamic> json) =>
      _$DistanceCalculationResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DistanceCalculationResponseDtoToJson(this);
}

@JsonSerializable()
class OverallDistanceStatsResponseDto {
  final bool success;
  final String? message;
  final OverallDistanceStatsDto data;

  OverallDistanceStatsResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory OverallDistanceStatsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$OverallDistanceStatsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OverallDistanceStatsResponseDtoToJson(this);
}
