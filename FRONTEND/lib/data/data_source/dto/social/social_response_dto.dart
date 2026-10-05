import 'package:json_annotation/json_annotation.dart';
import 'social_dto.dart';

part 'social_response_dto.g.dart';

@JsonSerializable()
class SocialShareResponseDto {
  final bool success;
  final String? message;
  final SocialShareDto data;

  SocialShareResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory SocialShareResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SocialShareResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SocialShareResponseDtoToJson(this);
}

@JsonSerializable()
class SocialPlatformsResponseDto {
  final bool success;
  final String? message;
  final List<SocialPlatformDto> data;

  SocialPlatformsResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory SocialPlatformsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SocialPlatformsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SocialPlatformsResponseDtoToJson(this);
}

@JsonSerializable()
class SocialStatisticsResponseDto {
  final bool success;
  final String? message;
  final SocialStatisticsDto data;

  SocialStatisticsResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory SocialStatisticsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SocialStatisticsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SocialStatisticsResponseDtoToJson(this);
}

@JsonSerializable()
class ShareGeneratedResponseDto {
  final bool success;
  final String message;
  final ShareGeneratedDto data;

  ShareGeneratedResponseDto({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ShareGeneratedResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ShareGeneratedResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ShareGeneratedResponseDtoToJson(this);
}

@JsonSerializable()
class SocialSharesResponseDto {
  final bool success;
  final String? message;
  final List<SocialShareDto> data;
  final PaginationMetaDto? meta;

  SocialSharesResponseDto({
    required this.success,
    this.message,
    required this.data,
    this.meta,
  });

  factory SocialSharesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SocialSharesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SocialSharesResponseDtoToJson(this);
}

@JsonSerializable()
class SocialAnalyticsResponseDto {
  final bool success;
  final String? message;
  final SocialAnalyticsDto data;

  SocialAnalyticsResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory SocialAnalyticsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SocialAnalyticsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SocialAnalyticsResponseDtoToJson(this);
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
