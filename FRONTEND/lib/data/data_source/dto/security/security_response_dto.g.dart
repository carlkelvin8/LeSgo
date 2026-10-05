// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecurityDashboardResponseDto _$SecurityDashboardResponseDtoFromJson(
  Map<String, dynamic> json,
) => SecurityDashboardResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: SecurityDashboardDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SecurityDashboardResponseDtoToJson(
  SecurityDashboardResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

TwoFactorSetupResponseDto _$TwoFactorSetupResponseDtoFromJson(
  Map<String, dynamic> json,
) => TwoFactorSetupResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: TwoFactorSetupDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TwoFactorSetupResponseDtoToJson(
  TwoFactorSetupResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

TwoFactorVerifyResponseDto _$TwoFactorVerifyResponseDtoFromJson(
  Map<String, dynamic> json,
) => TwoFactorVerifyResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: json['data'] == null
      ? null
      : TwoFactorVerifyDataDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TwoFactorVerifyResponseDtoToJson(
  TwoFactorVerifyResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

TwoFactorVerifyDataDto _$TwoFactorVerifyDataDtoFromJson(
  Map<String, dynamic> json,
) => TwoFactorVerifyDataDto(
  backupCodes: (json['backup_codes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$TwoFactorVerifyDataDtoToJson(
  TwoFactorVerifyDataDto instance,
) => <String, dynamic>{'backup_codes': instance.backupCodes};

BiometricsListResponseDto _$BiometricsListResponseDtoFromJson(
  Map<String, dynamic> json,
) => BiometricsListResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: (json['data'] as List<dynamic>)
      .map((e) => BiometricDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BiometricsListResponseDtoToJson(
  BiometricsListResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

AuditLogsResponseDto _$AuditLogsResponseDtoFromJson(
  Map<String, dynamic> json,
) => AuditLogsResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: (json['data'] as List<dynamic>)
      .map((e) => AuditLogDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : PaginationMetaDto.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuditLogsResponseDtoToJson(
  AuditLogsResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'meta': instance.meta,
};

SessionsResponseDto _$SessionsResponseDtoFromJson(Map<String, dynamic> json) =>
    SessionsResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>)
          .map((e) => SessionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SessionsResponseDtoToJson(
  SessionsResponseDto instance,
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

SimpleResponseDto _$SimpleResponseDtoFromJson(Map<String, dynamic> json) =>
    SimpleResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$SimpleResponseDtoToJson(SimpleResponseDto instance) =>
    <String, dynamic>{'success': instance.success, 'message': instance.message};
