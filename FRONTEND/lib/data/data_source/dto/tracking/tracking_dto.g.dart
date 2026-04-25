// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracking_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackingDto _$TrackingDtoFromJson(Map<String, dynamic> json) => TrackingDto(
  orderId: (json['order_id'] as num).toInt(),
  driverId: (json['driver_id'] as num?)?.toInt(),
  currentLat: (json['current_lat'] as num?)?.toDouble(),
  currentLng: (json['current_lng'] as num?)?.toDouble(),
  status: json['status'] as String,
  estimatedArrival: json['estimated_arrival'] as String?,
  distanceRemainingM: (json['distance_remaining_m'] as num?)?.toInt(),
  pickupLatitude: (json['pickup_latitude'] as num).toDouble(),
  pickupLongitude: (json['pickup_longitude'] as num).toDouble(),
  dropoffLatitude: (json['dropoff_latitude'] as num).toDouble(),
  dropoffLongitude: (json['dropoff_longitude'] as num).toDouble(),
  createdAt: json['created_at'] as String,
  acceptedAt: json['accepted_at'] as String?,
  pickedUpAt: json['picked_up_at'] as String?,
  inTransitAt: json['in_transit_at'] as String?,
  completedAt: json['completed_at'] as String?,
  cancelledAt: json['cancelled_at'] as String?,
  updatedAt: json['updated_at'] as String,
  driver: json['driver'] == null
      ? null
      : DriverDto.fromJson(json['driver'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TrackingDtoToJson(TrackingDto instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'driver_id': instance.driverId,
      'current_lat': instance.currentLat,
      'current_lng': instance.currentLng,
      'status': instance.status,
      'estimated_arrival': instance.estimatedArrival,
      'distance_remaining_m': instance.distanceRemainingM,
      'pickup_latitude': instance.pickupLatitude,
      'pickup_longitude': instance.pickupLongitude,
      'dropoff_latitude': instance.dropoffLatitude,
      'dropoff_longitude': instance.dropoffLongitude,
      'created_at': instance.createdAt,
      'accepted_at': instance.acceptedAt,
      'picked_up_at': instance.pickedUpAt,
      'in_transit_at': instance.inTransitAt,
      'completed_at': instance.completedAt,
      'cancelled_at': instance.cancelledAt,
      'updated_at': instance.updatedAt,
      'driver': instance.driver,
    };

DriverDto _$DriverDtoFromJson(Map<String, dynamic> json) => DriverDto(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  phone: json['phone'] as String?,
  vehicleNumber: json['vehicle_number'] as String?,
  vehicleType: json['vehicle_type'] as String?,
  photoUrl: json['photo_url'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
);

Map<String, dynamic> _$DriverDtoToJson(DriverDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': instance.phone,
  'vehicle_number': instance.vehicleNumber,
  'vehicle_type': instance.vehicleType,
  'photo_url': instance.photoUrl,
  'rating': instance.rating,
};

LocationUpdateDto _$LocationUpdateDtoFromJson(Map<String, dynamic> json) =>
    LocationUpdateDto(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$LocationUpdateDtoToJson(LocationUpdateDto instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'accuracy': instance.accuracy,
      'speed': instance.speed,
      'heading': instance.heading,
    };

RouteDto _$RouteDtoFromJson(Map<String, dynamic> json) => RouteDto(
  points: (json['points'] as List<dynamic>)
      .map((e) => RoutePointDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  distanceM: (json['distance_m'] as num).toInt(),
  durationS: (json['duration_s'] as num).toInt(),
);

Map<String, dynamic> _$RouteDtoToJson(RouteDto instance) => <String, dynamic>{
  'points': instance.points,
  'distance_m': instance.distanceM,
  'duration_s': instance.durationS,
};

RoutePointDto _$RoutePointDtoFromJson(Map<String, dynamic> json) =>
    RoutePointDto(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$RoutePointDtoToJson(RoutePointDto instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

EtaDto _$EtaDtoFromJson(Map<String, dynamic> json) => EtaDto(
  estimatedArrival: json['estimated_arrival'] as String,
  minutesRemaining: (json['minutes_remaining'] as num).toInt(),
  distanceRemainingM: (json['distance_remaining_m'] as num).toInt(),
  currentLatitude: (json['current_latitude'] as num).toDouble(),
  currentLongitude: (json['current_longitude'] as num).toDouble(),
);

Map<String, dynamic> _$EtaDtoToJson(EtaDto instance) => <String, dynamic>{
  'estimated_arrival': instance.estimatedArrival,
  'minutes_remaining': instance.minutesRemaining,
  'distance_remaining_m': instance.distanceRemainingM,
  'current_latitude': instance.currentLatitude,
  'current_longitude': instance.currentLongitude,
};
