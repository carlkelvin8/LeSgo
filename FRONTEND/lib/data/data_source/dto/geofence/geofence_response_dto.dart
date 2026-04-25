import 'package:json_annotation/json_annotation.dart';
import 'geofence_dto.dart';

part 'geofence_response_dto.g.dart';

@JsonSerializable()
class GeofencesResponseDto {
  final bool success;
  final String? message;
  final List<GeofenceDto> data;
  final PaginationMetaDto? meta;

  GeofencesResponseDto({
    required this.success,
    this.message,
    required this.data,
    this.meta,
  });

  factory GeofencesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GeofencesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GeofencesResponseDtoToJson(this);
}

@JsonSerializable()
class GeofenceResponseDto {
  final bool success;
  final String? message;
  final GeofenceDto data;

  GeofenceResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory GeofenceResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GeofenceResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GeofenceResponseDtoToJson(this);
}

@JsonSerializable()
class GeofenceTypesResponseDto {
  final bool success;
  final String? message;
  final List<String> data;

  GeofenceTypesResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory GeofenceTypesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GeofenceTypesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GeofenceTypesResponseDtoToJson(this);
}

@JsonSerializable()
class NearbyGeofencesResponseDto {
  final bool success;
  final String? message;
  final List<NearbyGeofenceDto> data;

  NearbyGeofencesResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory NearbyGeofencesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$NearbyGeofencesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NearbyGeofencesResponseDtoToJson(this);
}

@JsonSerializable()
class GeofenceStatisticsResponseDto {
  final bool success;
  final String? message;
  final GeofenceStatisticsDto data;

  GeofenceStatisticsResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory GeofenceStatisticsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GeofenceStatisticsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GeofenceStatisticsResponseDtoToJson(this);
}

@JsonSerializable()
class GeofenceEventsResponseDto {
  final bool success;
  final String? message;
  final List<GeofenceEventDto> data;

  GeofenceEventsResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory GeofenceEventsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GeofenceEventsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GeofenceEventsResponseDtoToJson(this);
}

@JsonSerializable()
class LocationCheckResponseDto {
  final bool success;
  final String? message;
  final LocationCheckDto data;

  LocationCheckResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory LocationCheckResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LocationCheckResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LocationCheckResponseDtoToJson(this);
}

@JsonSerializable()
class LocationProcessResponseDto {
  final bool success;
  final String message;
  final LocationProcessDto data;

  LocationProcessResponseDto({
    required this.success,
    required this.message,
    required this.data,
  });

  factory LocationProcessResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LocationProcessResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LocationProcessResponseDtoToJson(this);
}

@JsonSerializable()
class PaginationMetaDto {
  @JsonKey(name: 'current_page')
  final int currentPage;
  @JsonKey(name: 'last_page')
  final int lastPage;
  @JsonKey(name: 'per_page')
  final int perPage;
  final int total;

  PaginationMetaDto({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationMetaDto.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationMetaDtoToJson(this);
}
