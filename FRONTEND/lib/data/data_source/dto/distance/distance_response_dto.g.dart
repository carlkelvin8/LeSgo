// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'distance_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DistanceCalculationResponseDto _$DistanceCalculationResponseDtoFromJson(
  Map<String, dynamic> json,
) => DistanceCalculationResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: DistanceCalculationDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DistanceCalculationResponseDtoToJson(
  DistanceCalculationResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

OverallDistanceStatsResponseDto _$OverallDistanceStatsResponseDtoFromJson(
  Map<String, dynamic> json,
) => OverallDistanceStatsResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: OverallDistanceStatsDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OverallDistanceStatsResponseDtoToJson(
  OverallDistanceStatsResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};
