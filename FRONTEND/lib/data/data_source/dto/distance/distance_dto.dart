import 'package:json_annotation/json_annotation.dart';

part 'distance_dto.g.dart';

@JsonSerializable()
class DistanceCalculationDto {
  @JsonKey(name: 'distance_km')
  final double distanceKm;
  @JsonKey(name: 'distance_m')
  final double distanceM;
  final String unit;

  DistanceCalculationDto({
    required this.distanceKm,
    required this.distanceM,
    required this.unit,
  });

  factory DistanceCalculationDto.fromJson(Map<String, dynamic> json) =>
      _$DistanceCalculationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DistanceCalculationDtoToJson(this);
}

@JsonSerializable()
class OverallDistanceStatsDto {
  @JsonKey(name: 'total_distance_km')
  final double totalDistanceKm;
  @JsonKey(name: 'total_orders')
  final int totalOrders;
  @JsonKey(name: 'average_distance_km')
  final double averageDistanceKm;

  OverallDistanceStatsDto({
    required this.totalDistanceKm,
    required this.totalOrders,
    required this.averageDistanceKm,
  });

  factory OverallDistanceStatsDto.fromJson(Map<String, dynamic> json) =>
      _$OverallDistanceStatsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OverallDistanceStatsDtoToJson(this);
}
