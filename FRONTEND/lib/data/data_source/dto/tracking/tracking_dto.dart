import 'package:json_annotation/json_annotation.dart';

part 'tracking_dto.g.dart';

@JsonSerializable()
class TrackingDto {
  @JsonKey(name: 'order_id')
  final int orderId;
  @JsonKey(name: 'driver_id')
  final int? driverId;
  @JsonKey(name: 'current_lat')
  final double? currentLat;
  @JsonKey(name: 'current_lng')
  final double? currentLng;
  final String status;
  @JsonKey(name: 'estimated_arrival')
  final String? estimatedArrival;
  @JsonKey(name: 'distance_remaining_m')
  final int? distanceRemainingM;
  @JsonKey(name: 'pickup_latitude')
  final double pickupLatitude;
  @JsonKey(name: 'pickup_longitude')
  final double pickupLongitude;
  @JsonKey(name: 'dropoff_latitude')
  final double dropoffLatitude;
  @JsonKey(name: 'dropoff_longitude')
  final double dropoffLongitude;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'accepted_at')
  final String? acceptedAt;
  @JsonKey(name: 'picked_up_at')
  final String? pickedUpAt;
  @JsonKey(name: 'in_transit_at')
  final String? inTransitAt;
  @JsonKey(name: 'completed_at')
  final String? completedAt;
  @JsonKey(name: 'cancelled_at')
  final String? cancelledAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final DriverDto? driver;

  TrackingDto({
    required this.orderId,
    this.driverId,
    this.currentLat,
    this.currentLng,
    required this.status,
    this.estimatedArrival,
    this.distanceRemainingM,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.inTransitAt,
    this.completedAt,
    this.cancelledAt,
    required this.updatedAt,
    this.driver,
  });

  factory TrackingDto.fromJson(Map<String, dynamic> json) =>
      _$TrackingDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TrackingDtoToJson(this);
}

@JsonSerializable()
class DriverDto {
  final int id;
  final String name;
  final String? phone;
  @JsonKey(name: 'vehicle_number')
  final String? vehicleNumber;
  @JsonKey(name: 'vehicle_type')
  final String? vehicleType;
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  final double? rating;

  DriverDto({
    required this.id,
    required this.name,
    this.phone,
    this.vehicleNumber,
    this.vehicleType,
    this.photoUrl,
    this.rating,
  });

  factory DriverDto.fromJson(Map<String, dynamic> json) =>
      _$DriverDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DriverDtoToJson(this);
}

@JsonSerializable()
class LocationUpdateDto {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;

  LocationUpdateDto({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
  });

  factory LocationUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$LocationUpdateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LocationUpdateDtoToJson(this);
}

@JsonSerializable()
class RouteDto {
  final List<RoutePointDto> points;
  @JsonKey(name: 'distance_m')
  final int distanceM;
  @JsonKey(name: 'duration_s')
  final int durationS;

  RouteDto({
    required this.points,
    required this.distanceM,
    required this.durationS,
  });

  factory RouteDto.fromJson(Map<String, dynamic> json) =>
      _$RouteDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RouteDtoToJson(this);
}

@JsonSerializable()
class RoutePointDto {
  final double latitude;
  final double longitude;

  RoutePointDto({
    required this.latitude,
    required this.longitude,
  });

  factory RoutePointDto.fromJson(Map<String, dynamic> json) =>
      _$RoutePointDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RoutePointDtoToJson(this);
}

@JsonSerializable()
class EtaDto {
  @JsonKey(name: 'estimated_arrival')
  final String estimatedArrival;
  @JsonKey(name: 'minutes_remaining')
  final int minutesRemaining;
  @JsonKey(name: 'distance_remaining_m')
  final int distanceRemainingM;
  @JsonKey(name: 'current_latitude')
  final double currentLatitude;
  @JsonKey(name: 'current_longitude')
  final double currentLongitude;

  EtaDto({
    required this.estimatedArrival,
    required this.minutesRemaining,
    required this.distanceRemainingM,
    required this.currentLatitude,
    required this.currentLongitude,
  });

  factory EtaDto.fromJson(Map<String, dynamic> json) =>
      _$EtaDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EtaDtoToJson(this);
}
