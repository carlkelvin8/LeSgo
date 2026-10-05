import '../constants/api_constants.dart';
import '../di/injection.dart';
import '../network/dio_client.dart';

class SecurityBiometric {
  final int id;
  final String biometricType;
  final String deviceId;
  final String? deviceName;
  final String createdAt;

  const SecurityBiometric({
    required this.id,
    required this.biometricType,
    required this.deviceId,
    this.deviceName,
    required this.createdAt,
  });

  factory SecurityBiometric.fromJson(Map<String, dynamic> json) {
    final deviceInfo = json['device_info'];
    return SecurityBiometric(
      id: (json['id'] as num?)?.toInt() ?? 0,
      biometricType: json['biometric_type']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      deviceName: deviceInfo is Map
          ? deviceInfo['device_name']?.toString()
          : json['device_name']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class SecurityAuditLog {
  final int id;
  final String action;
  final String? ipAddress;
  final String createdAt;

  const SecurityAuditLog({
    required this.id,
    required this.action,
    this.ipAddress,
    required this.createdAt,
  });

  factory SecurityAuditLog.fromJson(Map<String, dynamic> json) {
    return SecurityAuditLog(
      id: (json['id'] as num?)?.toInt() ?? 0,
      action: json['action']?.toString() ?? json['event']?.toString() ?? '',
      ipAddress: json['ip_address']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class SecurityApi {
  SecurityApi._();

  static final _dio = getIt<DioClient>().dio;

  static Future<Map<String, dynamic>> setup2fa() async {
    final res = await _dio.post(ApiConstants.security2faSetup);
    final data = Map<String, dynamic>.from(
      (res.data['data'] ?? res.data) as Map,
    );
    if (data['qr_code'] == null && data['qr_code_url'] != null) {
      data['qr_code'] = data['qr_code_url'];
    }
    return data;
  }

  static Future<void> verify2fa(String code) async {
    await _dio.post(ApiConstants.security2faVerify, data: {'code': code});
  }

  static Future<void> disable2fa() async {
    await _dio.post(ApiConstants.security2faDisable);
  }

  static Future<List<String>> regenerateBackupCodes() async {
    final res = await _dio.post(ApiConstants.security2faRegenerateCodes);
    final data = res.data['data'] as Map<String, dynamic>? ?? {};
    return List<String>.from(data['backup_codes'] ?? []);
  }

  static Future<List<SecurityBiometric>> listBiometrics() async {
    final res = await _dio.get(ApiConstants.securityBiometrics);
    final list = res.data['data'] as List? ?? [];
    return list
        .whereType<Map>()
        .map((e) => SecurityBiometric.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> enrollBiometric({
    required String biometricType,
    required String deviceId,
    required String deviceName,
  }) async {
    await _dio.post(
      ApiConstants.securityBiometricEnroll,
      data: {
        'biometric_type': biometricType,
        'device_id': deviceId,
        'biometric_template': 'local_device_enrollment',
        'device_info': {'device_name': deviceName},
      },
    );
  }

  static Future<void> deactivateBiometric({required int biometricId}) async {
    await _dio.post(
      ApiConstants.securityBiometricDeactivate,
      data: {'biometric_id': biometricId},
    );
  }

  static Future<List<SecurityAuditLog>> getAuditLogs({int perPage = 20}) async {
    final res = await _dio.get(
      ApiConstants.securityAuditLogs,
      queryParameters: {'per_page': perPage},
    );
    final list = res.data['data'] as List? ?? [];
    return list
        .whereType<Map>()
        .map((e) => SecurityAuditLog.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
