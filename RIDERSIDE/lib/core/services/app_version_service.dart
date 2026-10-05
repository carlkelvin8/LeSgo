import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/api_constants.dart';
import '../utils/app_logger.dart';
import 'mobile_config_service.dart';

class AppVersionCheck {
  const AppVersionCheck({
    required this.forceUpdate,
    required this.currentBuild,
    required this.minimumBuild,
    this.message,
    this.storeUrl,
  });

  final bool forceUpdate;
  final int currentBuild;
  final int minimumBuild;
  final String? message;
  final String? storeUrl;
}

class AppVersionService {
  AppVersionService._();

  static Future<AppVersionCheck?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final response = await dio.get(ApiConstants.appRiderVersion);
      final data = response.data;
      var payload = data is Map ? (data['data'] ?? data) : null;

      if (payload is! Map || payload['min_build'] == null) {
        final config = await MobileConfigService.instance.load();
        payload = config['rider_app'] as Map? ?? payload;
      }

      if (payload is! Map) return null;

      final minimumBuild = _parseInt(payload['min_build'] ?? payload['min_build_number']);
      if (minimumBuild == null) return null;

      final forceUpdate = currentBuild < minimumBuild;
      if (!forceUpdate) return null;

      return AppVersionCheck(
        forceUpdate: true,
        currentBuild: currentBuild,
        minimumBuild: minimumBuild,
        message: payload['message']?.toString(),
        storeUrl: payload['store_url']?.toString(),
      );
    } catch (e) {
      AppLogger.debug('Version check skipped: $e');
      return null;
    }
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }
}
