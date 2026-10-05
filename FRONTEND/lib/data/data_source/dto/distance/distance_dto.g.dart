// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'distance_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DistanceCalculationDto _$DistanceCalculationDtoFromJson(
  Map<String, dynamic> json,
) => DistanceCalculationDto(
  distanceKm: (json['distance_km'] as num).toDouble(),
  distanceM: (json['distance_m'] as num).toDouble(),
  unit: json['unit'] as String,
);

Map<String, dynamic> _$DistanceCalculationDtoToJson(
  DistanceCalculationDto instance,
) => <String, dynamic>{
  'distance_km': instance.distanceKm,
  'distance_m': instance.distanceM,
  'unit': instance.unit,
};

OverallDistanceStatsDto _$OverallDistanceStatsDtoFromJson(
  Map<String, dynamic> json,
) => OverallDistanceStatsDto(
  totalDistanceKm: (json['total_distance_km'] as num).toDouble(),
  totalOrders: (json['total_orders'] as num).toInt(),
  averageDistanceKm: (json['average_distance_km'] as num).toDouble(),
);

Map<String, dynamic> _$OverallDistanceStatsDtoToJson(
  OverallDistanceStatsDto instance,
) => <String, dynamic>{
  'total_distance_km': instance.totalDistanceKm,
  'total_orders': instance.totalOrders,
  'average_distance_km': instance.averageDistanceKm,
};
