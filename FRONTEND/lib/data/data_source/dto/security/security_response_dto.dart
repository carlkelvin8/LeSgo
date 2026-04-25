import 'package:json_annotation/json_annotation.dart';
import 'security_dto.dart';

part 'security_response_dto.g.dart';

@JsonSerializable()
class SecurityDashboardResponseDto {
  final bool success;
  final String? message;
  final SecurityDashboardDto data;

  SecurityDashboardResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory SecurityDashboardResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SecurityDashboardResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityDashboardResponseDtoToJson(this);
}

@JsonSerializable()
class TwoFactorSetupResponseDto {
  final bool success;
  final String? message;
  final TwoFactorSetupDto data;

  TwoFactorSetupResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory TwoFactorSetupResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TwoFactorSetupResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TwoFactorSetupResponseDtoToJson(this);
}

@JsonSerializable()
class TwoFactorVerifyResponseDto {
  final bool success;
  final String message;
  @JsonKey(name: 'data')
  final TwoFactorVerifyDataDto? data;

  TwoFactorVerifyResponseDto({
    required this.success,
    required this.message,
    this.data,
  });

  factory TwoFactorVerifyResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TwoFactorVerifyResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TwoFactorVerifyResponseDtoToJson(this);
}

@JsonSerializable()
class TwoFactorVerifyDataDto {
  @JsonKey(name: 'backup_codes')
  final List<String> backupCodes;

  TwoFactorVerifyDataDto({
    required this.backupCodes,
  });

  factory TwoFactorVerifyDataDto.fromJson(Map<String, dynamic> json) =>
      _$TwoFactorVerifyDataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TwoFactorVerifyDataDtoToJson(this);
}

@JsonSerializable()
class BiometricsListResponseDto {
  final bool success;
  final String? message;
  final List<BiometricDto> data;

  BiometricsListResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory BiometricsListResponseDto.fromJson(Map<String, dynamic> json) =>
      _$BiometricsListResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BiometricsListResponseDtoToJson(this);
}

@JsonSerializable()
class AuditLogsResponseDto {
  final bool success;
  final String? message;
  final List<AuditLogDto> data;
  final PaginationMetaDto? meta;

  AuditLogsResponseDto({
    required this.success,
    this.message,
    required this.data,
    this.meta,
  });

  factory AuditLogsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuditLogsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AuditLogsResponseDtoToJson(this);
}

@JsonSerializable()
class SessionsResponseDto {
  final bool success;
  final String? message;
  final List<SessionDto> data;

  SessionsResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory SessionsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SessionsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SessionsResponseDtoToJson(this);
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

@JsonSerializable()
class SimpleResponseDto {
  final bool success;
  final String message;

  SimpleResponseDto({
    required this.success,
    required this.message,
  });

  factory SimpleResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SimpleResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleResponseDtoToJson(this);
}
