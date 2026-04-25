// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecurityDashboardDto _$SecurityDashboardDtoFromJson(
  Map<String, dynamic> json,
) => SecurityDashboardDto(
  twoFactorEnabled: json['two_factor_enabled'] as bool,
  biometricEnabled: json['biometric_enabled'] as bool,
  activeSessions: (json['active_sessions'] as num).toInt(),
  lastLogin: json['last_login'] as String?,
  lastPasswordChange: json['last_password_change'] as String?,
);

Map<String, dynamic> _$SecurityDashboardDtoToJson(
  SecurityDashboardDto instance,
) => <String, dynamic>{
  'two_factor_enabled': instance.twoFactorEnabled,
  'biometric_enabled': instance.biometricEnabled,
  'active_sessions': instance.activeSessions,
  'last_login': instance.lastLogin,
  'last_password_change': instance.lastPasswordChange,
};

TwoFactorSetupDto _$TwoFactorSetupDtoFromJson(Map<String, dynamic> json) =>
    TwoFactorSetupDto(
      secret: json['secret'] as String,
      qrCode: json['qr_code'] as String,
      backupCodes: (json['backup_codes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TwoFactorSetupDtoToJson(TwoFactorSetupDto instance) =>
    <String, dynamic>{
      'secret': instance.secret,
      'qr_code': instance.qrCode,
      'backup_codes': instance.backupCodes,
    };

BiometricDto _$BiometricDtoFromJson(Map<String, dynamic> json) => BiometricDto(
  id: (json['id'] as num).toInt(),
  type: json['type'] as String,
  deviceName: json['device_name'] as String,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$BiometricDtoToJson(BiometricDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'device_name': instance.deviceName,
      'created_at': instance.createdAt,
    };

AuditLogDto _$AuditLogDtoFromJson(Map<String, dynamic> json) => AuditLogDto(
  id: (json['id'] as num).toInt(),
  action: json['action'] as String,
  ipAddress: json['ip_address'] as String?,
  userAgent: json['user_agent'] as String?,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$AuditLogDtoToJson(AuditLogDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'ip_address': instance.ipAddress,
      'user_agent': instance.userAgent,
      'created_at': instance.createdAt,
    };

SessionDto _$SessionDtoFromJson(Map<String, dynamic> json) => SessionDto(
  id: (json['id'] as num).toInt(),
  deviceName: json['device_name'] as String,
  ipAddress: json['ip_address'] as String?,
  lastActive: json['last_active'] as String,
  isCurrent: json['is_current'] as bool,
);

Map<String, dynamic> _$SessionDtoToJson(SessionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'device_name': instance.deviceName,
      'ip_address': instance.ipAddress,
      'last_active': instance.lastActive,
      'is_current': instance.isCurrent,
    };
