import 'package:json_annotation/json_annotation.dart';

part 'security_dto.g.dart';

@JsonSerializable()
class SecurityDashboardDto {
  @JsonKey(name: 'two_factor_enabled')
  final bool twoFactorEnabled;
  @JsonKey(name: 'biometric_enabled')
  final bool biometricEnabled;
  @JsonKey(name: 'active_sessions')
  final int activeSessions;
  @JsonKey(name: 'last_login')
  final String? lastLogin;
  @JsonKey(name: 'last_password_change')
  final String? lastPasswordChange;

  SecurityDashboardDto({
    required this.twoFactorEnabled,
    required this.biometricEnabled,
    required this.activeSessions,
    this.lastLogin,
    this.lastPasswordChange,
  });

  factory SecurityDashboardDto.fromJson(Map<String, dynamic> json) =>
      _$SecurityDashboardDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityDashboardDtoToJson(this);
}

@JsonSerializable()
class TwoFactorSetupDto {
  final String secret;
  @JsonKey(name: 'qr_code')
  final String qrCode;
  @JsonKey(name: 'backup_codes')
  final List<String> backupCodes;

  TwoFactorSetupDto({
    required this.secret,
    required this.qrCode,
    required this.backupCodes,
  });

  factory TwoFactorSetupDto.fromJson(Map<String, dynamic> json) =>
      _$TwoFactorSetupDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TwoFactorSetupDtoToJson(this);
}

@JsonSerializable()
class BiometricDto {
  final int id;
  final String type;
  @JsonKey(name: 'device_name')
  final String deviceName;
  @JsonKey(name: 'created_at')
  final String createdAt;

  BiometricDto({
    required this.id,
    required this.type,
    required this.deviceName,
    required this.createdAt,
  });

  factory BiometricDto.fromJson(Map<String, dynamic> json) =>
      _$BiometricDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BiometricDtoToJson(this);
}

@JsonSerializable()
class AuditLogDto {
  final int id;
  final String action;
  @JsonKey(name: 'ip_address')
  final String? ipAddress;
  @JsonKey(name: 'user_agent')
  final String? userAgent;
  @JsonKey(name: 'created_at')
  final String createdAt;

  AuditLogDto({
    required this.id,
    required this.action,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory AuditLogDto.fromJson(Map<String, dynamic> json) =>
      _$AuditLogDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AuditLogDtoToJson(this);
}

@JsonSerializable()
class SessionDto {
  final int id;
  @JsonKey(name: 'device_name')
  final String deviceName;
  @JsonKey(name: 'ip_address')
  final String? ipAddress;
  @JsonKey(name: 'last_active')
  final String lastActive;
  @JsonKey(name: 'is_current')
  final bool isCurrent;

  SessionDto({
    required this.id,
    required this.deviceName,
    this.ipAddress,
    required this.lastActive,
    required this.isCurrent,
  });

  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SessionDtoToJson(this);
}
