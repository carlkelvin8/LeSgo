// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracking_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackingResponseDto _$TrackingResponseDtoFromJson(Map<String, dynamic> json) =>
    TrackingResponseDto(
      success: json['success'] as bool,
      data: TrackingDto.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TrackingResponseDtoToJson(
  TrackingResponseDto instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

RouteResponseDto _$RouteResponseDtoFromJson(Map<String, dynamic> json) =>
    RouteResponseDto(
      success: json['success'] as bool,
      data: RouteDto.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RouteResponseDtoToJson(RouteResponseDto instance) =>
    <String, dynamic>{'success': instance.success, 'data': instance.data};

EtaResponseDto _$EtaResponseDtoFromJson(Map<String, dynamic> json) =>
    EtaResponseDto(
      success: json['success'] as bool,
      data: EtaDto.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EtaResponseDtoToJson(EtaResponseDto instance) =>
    <String, dynamic>{'success': instance.success, 'data': instance.data};
