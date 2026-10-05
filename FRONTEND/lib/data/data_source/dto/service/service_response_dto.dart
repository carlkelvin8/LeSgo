import 'package:json_annotation/json_annotation.dart';
import 'service_dto.dart';

part 'service_response_dto.g.dart';

@JsonSerializable()
class ServiceResponseDto {
  final bool success;
  final ServiceDto? data;
  final String? error;

  ServiceResponseDto({
    required this.success,
    this.data,
    this.error,
  });

  factory ServiceResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ServiceResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceResponseDtoToJson(this);

  factory ServiceResponseDto.withError(String errorMessage) {
    return ServiceResponseDto(
      success: false,
      data: null,
      error: errorMessage,
    );
  }
}
