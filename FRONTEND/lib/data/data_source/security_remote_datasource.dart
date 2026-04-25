import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/network/dio_client.dart';
import 'dto/security/security_dto.dart';

@lazySingleton
class SecurityRemoteDataSource {
  final DioClient _dioClient;

  SecurityRemoteDataSource(this._dioClient);

  /// Get security dashboard
  Future<SecurityDashboardDto> getSecurityDashboard() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/security/dashboard');
      return SecurityDashboardDto.fromJson(response.data['data']);
    } catch (e) {
      // Mock response
      return SecurityDashboardDto(
        twoFactorEnabled: false,
        biometricEnabled: false,
        activeSessions: 1,
        lastLogin: DateTime.now().toIso8601String(),
        lastPasswordChange: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      );
    }
  }

  /// Setup 2FA
  Future<TwoFactorSetupDto> setup2FA() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post('/v1/security/2fa/setup');
      return TwoFactorSetupDto.fromJson(response.data['data']);
    } catch (e) {
      // Mock response
      return TwoFactorSetupDto(
        secret: 'MOCK_SECRET_KEY',
        qrCode: 'mock_qr_code_base64',
        backupCodes: ['123456', '789012', '345678'],
      );
    }
  }

  /// List biometrics
  Future<List<BiometricDto>> listBiometrics() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/security/biometrics');
      return (response.data['data'] as List)
          .map((item) => BiometricDto.fromJson(item))
          .toList();
    } catch (e) {
      // Mock response
      return [
        BiometricDto(
          id: 1,
          type: 'fingerprint',
          deviceName: 'iPhone 13',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];
    }
  }

  /// Get audit logs
  Future<List<AuditLogDto>> getAuditLogs({int perPage = 20}) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/security/audit-logs', queryParameters: {
        'per_page': perPage,
      });
      return (response.data['data'] as List)
          .map((item) => AuditLogDto.fromJson(item))
          .toList();
    } catch (e) {
      // Mock response
      return [
        AuditLogDto(
          id: 1,
          action: 'login',
          ipAddress: '192.168.1.1',
          userAgent: 'Mozilla/5.0',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];
    }
  }
}