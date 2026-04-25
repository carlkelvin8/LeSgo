import 'package:json_annotation/json_annotation.dart';

part 'geofence_dto.g.dart';

@JsonSerializable()
class GeofenceDto {
  final int id;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  @JsonKey(name: 'radius_km')
  final double radiusKm;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  GeofenceDto({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory GeofenceDto.fromJson(Map<String, dynamic> json) =>
      _$GeofenceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GeofenceDtoToJson(this);
}

@JsonSerializable()
class NearbyGeofenceDto {
  final int id;
  final String name;
  final String type;
  @JsonKey(name: 'distance_km')
  final double distanceKm;
  @JsonKey(name: 'is_active')
  final bool isActive;

  NearbyGeofenceDto({
    required this.id,
    required this.name,
    required this.type,
    required this.distanceKm,
    required this.isActive,
  });

  factory NearbyGeofenceDto.fromJson(Map<String, dynamic> json) =>
      _$NearbyGeofenceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NearbyGeofenceDtoToJson(this);
}

@JsonSerializable()
class GeofenceStatisticsDto {
  @JsonKey(name: 'total_geofences')
  final int totalGeofences;
  @JsonKey(name: 'active_geofences')
  final int activeGeofences;
  @JsonKey(name: 'total_entries_today')
  final int totalEntriesToday;
  @JsonKey(name: 'total_orders_from_geofences')
  final int totalOrdersFromGeofences;

  GeofenceStatisticsDto({
    required this.totalGeofences,
    required this.activeGeofences,
    required this.totalEntriesToday,
    required this.totalOrdersFromGeofences,
  });

  factory GeofenceStatisticsDto.fromJson(Map<String, dynamic> json) =>
      _$GeofenceStatisticsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GeofenceStatisticsDtoToJson(this);
}

@JsonSerializable()
class GeofenceEventDto {
  final int id;
  @JsonKey(name: 'geofence_id')
  final int geofenceId;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'event_type')
  final String eventType;
  final double latitude;
  final double longitude;
  @JsonKey(name: 'created_at')
  final String createdAt;

  GeofenceEventDto({
    required this.id,
    required this.geofenceId,
    required this.userId,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  factory GeofenceEventDto.fromJson(Map<String, dynamic> json) =>
      _$GeofenceEventDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GeofenceEventDtoToJson(this);
}

@JsonSerializable()
class LocationCheckDto {
  @JsonKey(name: 'inside_geofence')
  final bool insideGeofence;
  final List<GeofenceInfoDto> geofences;

  LocationCheckDto({
    required this.insideGeofence,
    required this.geofences,
  });

  factory LocationCheckDto.fromJson(Map<String, dynamic> json) =>
      _$LocationCheckDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LocationCheckDtoToJson(this);
}

@JsonSerializable()
class GeofenceInfoDto {
  final int id;
  final String name;
  final String type;

  GeofenceInfoDto({
    required this.id,
    required this.name,
    required this.type,
  });

  factory GeofenceInfoDto.fromJson(Map<String, dynamic> json) =>
      _$GeofenceInfoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GeofenceInfoDtoToJson(this);
}

@JsonSerializable()
class LocationProcessDto {
  @JsonKey(name: 'geofence_id')
  final int geofenceId;
  @JsonKey(name: 'event_type')
  final String eventType;

  LocationProcessDto({
    required this.geofenceId,
    required this.eventType,
  });

  factory LocationProcessDto.fromJson(Map<String, dynamic> json) =>
      _$LocationProcessDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LocationProcessDtoToJson(this);
}
