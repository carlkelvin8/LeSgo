import 'package:json_annotation/json_annotation.dart';
import 'tracking_dto.dart';

part 'tracking_response_dto.g.dart';

@JsonSerializable()
class TrackingResponseDto {
  final bool success;
  final TrackingDto data;

  TrackingResponseDto({
    required this.success,
    required this.data,
  });

  factory TrackingResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TrackingResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TrackingResponseDtoToJson(this);
}

@JsonSerializable()
class RouteResponseDto {
  final bool success;
  final RouteDto data;

  RouteResponseDto({
    required this.success,
    required this.data,
  });

  factory RouteResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RouteResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RouteResponseDtoToJson(this);
}

@JsonSerializable()
class EtaResponseDto {
  final bool success;
  final EtaDto data;

  EtaResponseDto({
    required this.success,
    required this.data,
  });

  factory EtaResponseDto.fromJson(Map<String, dynamic> json) =>
      _$EtaResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EtaResponseDtoToJson(this);
}
