import 'package:json_annotation/json_annotation.dart';
import 'service_dto.dart';

part 'services_response_dto.g.dart';

@JsonSerializable()
class ServicesResponseDto {
  final bool success;
  final List<ServiceDto> data;
  final MetaDto meta;
  final String? error;

  ServicesResponseDto({
    required this.success,
    required this.data,
    required this.meta,
    this.error,
  });

  factory ServicesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ServicesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ServicesResponseDtoToJson(this);

  factory ServicesResponseDto.withError(String errorMessage) {
    return ServicesResponseDto(
      success: false,
      data: [],
      meta: MetaDto(currentPage: 1, lastPage: 1, perPage: 20, total: 0),
      error: errorMessage,
    );
  }
}

@JsonSerializable()
class MetaDto {
  @JsonKey(name: 'current_page')
  final int currentPage;
  @JsonKey(name: 'last_page')
  final int lastPage;
  @JsonKey(name: 'per_page')
  final int perPage;
  final int total;

  MetaDto({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory MetaDto.fromJson(Map<String, dynamic> json) =>
      _$MetaDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MetaDtoToJson(this);
}
