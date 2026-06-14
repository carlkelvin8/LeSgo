import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../constants/app_info.dart';
import '../utils/app_logger.dart';

class MobileConfigService {
  MobileConfigService._();

  static final MobileConfigService instance = MobileConfigService._();

  Map<String, dynamic>? _cached;
  DateTime? _loadedAt;

  static const _cacheDuration = Duration(minutes: 30);

  Future<Map<String, dynamic>> load({bool force = false}) async {
    if (!force &&
        _cached != null &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < _cacheDuration) {
      return _cached!;
    }

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final response = await dio.get(ApiConstants.configMobile);
      final body = response.data;
      final data = body is Map ? (body['data'] ?? body) : null;
      if (data is Map) {
        _cached = Map<String, dynamic>.from(data);
        _loadedAt = DateTime.now();
        return _cached!;
      }
    } catch (e) {
      AppLogger.debug('Mobile config load failed: $e');
    }

    return _cached ?? {};
  }

  Map<String, dynamic> get riderApp =>
      Map<String, dynamic>.from(_cached?['rider_app'] as Map? ?? {});

  Map<String, dynamic> get safety =>
      Map<String, dynamic>.from(_cached?['safety'] as Map? ?? {});

  List<String> get supportCategories {
    final raw = _cached?['support_categories'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [
      'general',
      'payments',
      'orders',
      'account',
      'technical',
      'safety',
    ];
  }

  String get supportPhone =>
      safety['support_phone']?.toString() ?? '+639171234567';

  String get emergencyNumber =>
      safety['emergency_number']?.toString() ?? '911';

  String get supportEmail =>
      safety['support_email']?.toString() ?? AppInfo.supportEmail;

  int get riderMinBuild {
    final value = riderApp['min_build'] ?? riderApp['min_build_number'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }

  String? get riderStoreUrl => riderApp['store_url']?.toString();

  String? get riderUpdateMessage => riderApp['message']?.toString();
}
