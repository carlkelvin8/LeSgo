// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'estimate_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EstimateRequestDto _$EstimateRequestDtoFromJson(Map<String, dynamic> json) =>
    EstimateRequestDto(
      serviceId: (json['service_id'] as num).toInt(),
      pickupLat: (json['pickup_lat'] as num).toDouble(),
      pickupLng: (json['pickup_lng'] as num).toDouble(),
      dropoffLat: (json['dropoff_lat'] as num).toDouble(),
      dropoffLng: (json['dropoff_lng'] as num).toDouble(),
      estimatedDistanceM: (json['estimated_distance_m'] as num).toInt(),
    );

Map<String, dynamic> _$EstimateRequestDtoToJson(EstimateRequestDto instance) =>
    <String, dynamic>{
      'service_id': instance.serviceId,
      'pickup_lat': instance.pickupLat,
      'pickup_lng': instance.pickupLng,
      'dropoff_lat': instance.dropoffLat,
      'dropoff_lng': instance.dropoffLng,
      'estimated_distance_m': instance.estimatedDistanceM,
    };
