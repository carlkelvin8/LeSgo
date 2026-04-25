// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geofence_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeofenceDto _$GeofenceDtoFromJson(Map<String, dynamic> json) => GeofenceDto(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  type: json['type'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  radiusKm: (json['radius_km'] as num).toDouble(),
  isActive: json['is_active'] as bool,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$GeofenceDtoToJson(GeofenceDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radius_km': instance.radiusKm,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

NearbyGeofenceDto _$NearbyGeofenceDtoFromJson(Map<String, dynamic> json) =>
    NearbyGeofenceDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
      isActive: json['is_active'] as bool,
    );

Map<String, dynamic> _$NearbyGeofenceDtoToJson(NearbyGeofenceDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'distance_km': instance.distanceKm,
      'is_active': instance.isActive,
    };

GeofenceStatisticsDto _$GeofenceStatisticsDtoFromJson(
  Map<String, dynamic> json,
) => GeofenceStatisticsDto(
  totalGeofences: (json['total_geofences'] as num).toInt(),
  activeGeofences: (json['active_geofences'] as num).toInt(),
  totalEntriesToday: (json['total_entries_today'] as num).toInt(),
  totalOrdersFromGeofences: (json['total_orders_from_geofences'] as num)
      .toInt(),
);

Map<String, dynamic> _$GeofenceStatisticsDtoToJson(
  GeofenceStatisticsDto instance,
) => <String, dynamic>{
  'total_geofences': instance.totalGeofences,
  'active_geofences': instance.activeGeofences,
  'total_entries_today': instance.totalEntriesToday,
  'total_orders_from_geofences': instance.totalOrdersFromGeofences,
};

GeofenceEventDto _$GeofenceEventDtoFromJson(Map<String, dynamic> json) =>
    GeofenceEventDto(
      id: (json['id'] as num).toInt(),
      geofenceId: (json['geofence_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      eventType: json['event_type'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$GeofenceEventDtoToJson(GeofenceEventDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'geofence_id': instance.geofenceId,
      'user_id': instance.userId,
      'event_type': instance.eventType,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'created_at': instance.createdAt,
    };

LocationCheckDto _$LocationCheckDtoFromJson(Map<String, dynamic> json) =>
    LocationCheckDto(
      insideGeofence: json['inside_geofence'] as bool,
      geofences: (json['geofences'] as List<dynamic>)
          .map((e) => GeofenceInfoDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LocationCheckDtoToJson(LocationCheckDto instance) =>
    <String, dynamic>{
      'inside_geofence': instance.insideGeofence,
      'geofences': instance.geofences,
    };

GeofenceInfoDto _$GeofenceInfoDtoFromJson(Map<String, dynamic> json) =>
    GeofenceInfoDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$GeofenceInfoDtoToJson(GeofenceInfoDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
    };

LocationProcessDto _$LocationProcessDtoFromJson(Map<String, dynamic> json) =>
    LocationProcessDto(
      geofenceId: (json['geofence_id'] as num).toInt(),
      eventType: json['event_type'] as String,
    );

Map<String, dynamic> _$LocationProcessDtoToJson(LocationProcessDto instance) =>
    <String, dynamic>{
      'geofence_id': instance.geofenceId,
      'event_type': instance.eventType,
    };
