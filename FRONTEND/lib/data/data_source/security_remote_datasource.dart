import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/security/security_dto.dart';

@lazySingleton
class SecurityRemoteDataSource {
  final DioClient _dioClient;

  SecurityRemoteDataSource(this._dioClient);

  Future<SecurityDashboardDto> getSecurityDashboard() async {
    final response = await _dioClient.dio.get(ApiConstants.securityDashboard);
    final data = response.data['data'] ?? response.data;
    return SecurityDashboardDto.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  Future<TwoFactorSetupDto> setup2FA() async {
    final response = await _dioClient.dio.post(ApiConstants.security2faSetup);
    final data = Map<String, dynamic>.from(
      (response.data['data'] ?? response.data) as Map,
    );
    if (data['qr_code'] == null && data['qr_code_url'] != null) {
      data['qr_code'] = data['qr_code_url'];
    }
    return TwoFactorSetupDto.fromJson(data);
  }

  Future<void> verify2FA(String code) async {
    await _dioClient.dio.post(
      ApiConstants.security2faVerify,
      data: {'code': code},
    );
  }

  Future<void> disable2FA(String code) async {
    await _dioClient.dio.post(
      ApiConstants.security2faDisable,
      data: {'code': code},
    );
  }

  Future<List<String>> regenerateBackupCodes(String code) async {
    final response = await _dioClient.dio.post(
      ApiConstants.security2faRegenerateCodes,
      data: {'code': code},
    );
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return List<String>.from(data['backup_codes'] ?? []);
  }

  Future<List<BiometricDto>> listBiometrics() async {
    final response = await _dioClient.dio.get(ApiConstants.securityBiometrics);
    final list = response.data['data'] as List? ?? [];
    return list.map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      final deviceInfo = data['device_info'] is Map
          ? Map<String, dynamic>.from(data['device_info'] as Map)
          : const <String, dynamic>{};
      data['type'] ??= data['biometric_type'] ?? 'biometric';
      data['device_name'] ??=
          deviceInfo['device_name'] ?? data['device_id'] ?? 'Device';
      data['created_at'] ??=
          data['enrolled_at'] ?? DateTime.now().toIso8601String();
      return BiometricDto.fromJson(data);
    }).toList();
  }

  Future<void> enrollBiometric({
    required String biometricType,
    required String deviceId,
    required String deviceName,
  }) async {
    await _dioClient.dio.post(
      ApiConstants.securityBiometricEnroll,
      data: {
        'biometric_type': biometricType,
        'device_id': deviceId,
        'biometric_template': 'local_device_enrollment',
        'device_info': {'device_name': deviceName},
      },
    );
  }

  Future<void> deactivateBiometric({required int biometricId}) async {
    await _dioClient.dio.post(
      ApiConstants.securityBiometricDeactivate,
      data: {'biometric_id': biometricId},
    );
  }

  Future<List<AuditLogDto>> getAuditLogs({int perPage = 20}) async {
    final response = await _dioClient.dio.get(
      ApiConstants.securityAuditLogs,
      queryParameters: {'per_page': perPage},
    );
    final container = response.data['data'];
    final list = container is List
        ? container
        : container is Map
        ? container['data'] as List? ?? []
        : const [];
    return list.map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      data['created_at'] ??=
          data['occurred_at'] ?? DateTime.now().toIso8601String();
      data['action'] ??= data['event_type'] ?? 'Security activity';
      return AuditLogDto.fromJson(data);
    }).toList();
  }
}

String securityErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
  }
  return error.toString();
}
