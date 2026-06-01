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
    return SecurityDashboardDto.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<TwoFactorSetupDto> setup2FA() async {
    final response = await _dioClient.dio.post(ApiConstants.security2faSetup);
    final data = response.data['data'] ?? response.data;
    return TwoFactorSetupDto.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<BiometricDto>> listBiometrics() async {
    final response = await _dioClient.dio.get(ApiConstants.securityBiometrics);
    final list = response.data['data'] as List? ?? [];
    return list
        .map((item) => BiometricDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AuditLogDto>> getAuditLogs({int perPage = 20}) async {
    final response = await _dioClient.dio.get(
      ApiConstants.securityAuditLogs,
      queryParameters: {'per_page': perPage},
    );
    final list = response.data['data'] as List? ?? [];
    return list
        .map((item) => AuditLogDto.fromJson(item as Map<String, dynamic>))
        .toList();
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
