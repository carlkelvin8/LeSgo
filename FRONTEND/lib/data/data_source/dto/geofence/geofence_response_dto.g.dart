// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geofence_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeofencesResponseDto _$GeofencesResponseDtoFromJson(
  Map<String, dynamic> json,
) => GeofencesResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: (json['data'] as List<dynamic>)
      .map((e) => GeofenceDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : PaginationMetaDto.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GeofencesResponseDtoToJson(
  GeofencesResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'meta': instance.meta,
};

GeofenceResponseDto _$GeofenceResponseDtoFromJson(Map<String, dynamic> json) =>
    GeofenceResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: GeofenceDto.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GeofenceResponseDtoToJson(
  GeofenceResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

GeofenceTypesResponseDto _$GeofenceTypesResponseDtoFromJson(
  Map<String, dynamic> json,
) => GeofenceTypesResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: (json['data'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$GeofenceTypesResponseDtoToJson(
  GeofenceTypesResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

NearbyGeofencesResponseDto _$NearbyGeofencesResponseDtoFromJson(
  Map<String, dynamic> json,
) => NearbyGeofencesResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: (json['data'] as List<dynamic>)
      .map((e) => NearbyGeofenceDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$NearbyGeofencesResponseDtoToJson(
  NearbyGeofencesResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

GeofenceStatisticsResponseDto _$GeofenceStatisticsResponseDtoFromJson(
  Map<String, dynamic> json,
) => GeofenceStatisticsResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: GeofenceStatisticsDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GeofenceStatisticsResponseDtoToJson(
  GeofenceStatisticsResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

GeofenceEventsResponseDto _$GeofenceEventsResponseDtoFromJson(
  Map<String, dynamic> json,
) => GeofenceEventsResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: (json['data'] as List<dynamic>)
      .map((e) => GeofenceEventDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GeofenceEventsResponseDtoToJson(
  GeofenceEventsResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

LocationCheckResponseDto _$LocationCheckResponseDtoFromJson(
  Map<String, dynamic> json,
) => LocationCheckResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: LocationCheckDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LocationCheckResponseDtoToJson(
  LocationCheckResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

LocationProcessResponseDto _$LocationProcessResponseDtoFromJson(
  Map<String, dynamic> json,
) => LocationProcessResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: LocationProcessDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LocationProcessResponseDtoToJson(
  LocationProcessResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

PaginationMetaDto _$PaginationMetaDtoFromJson(Map<String, dynamic> json) =>
    PaginationMetaDto(
      currentPage: (json['current_page'] as num).toInt(),
      lastPage: (json['last_page'] as num).toInt(),
      perPage: (json['per_page'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationMetaDtoToJson(PaginationMetaDto instance) =>
    <String, dynamic>{
      'current_page': instance.currentPage,
      'last_page': instance.lastPage,
      'per_page': instance.perPage,
      'total': instance.total,
    };
