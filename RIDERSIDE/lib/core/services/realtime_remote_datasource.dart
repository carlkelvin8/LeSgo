import '../constants/api_constants.dart';
import '../di/injection.dart';
import '../network/dio_client.dart';

class RealtimeRemoteDataSource {
  RealtimeRemoteDataSource._();

  static final _dio = getIt<DioClient>().dio;

  static Future<Map<String, dynamic>> fetchConfig() async {
    final response = await _dio.get(ApiConstants.realtimeConfig);
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    final websocket = data['websocket'];
    if (websocket is Map) {
      return Map<String, dynamic>.from(websocket);
    }
    return {'enabled': false};
  }

  static Future<Map<String, dynamic>> connect({String platform = 'mobile'}) async {
    final response = await _dio.post(
      ApiConstants.realtimeConnect,
      data: {'platform': platform, 'device_name': 'lesgo_rider'},
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  static Future<void> ping(String connectionId) async {
    await _dio.post(
      ApiConstants.realtimePing,
      data: {'connection_id': connectionId},
    );
  }

  static Future<void> disconnect(String connectionId) async {
    await _dio.post(
      ApiConstants.realtimeDisconnect,
      data: {'connection_id': connectionId},
    );
  }

  static Future<List<Map<String, dynamic>>> fetchNotifications({
    bool unreadOnly = false,
    String? type,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.realtimeNotifications,
      queryParameters: {
        if (unreadOnly) 'unread_only': true,
        if (type != null) 'type': type,
        'per_page': perPage,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  static Future<void> markNotificationRead(int id) async {
    await _dio.post(ApiConstants.realtimeNotificationRead(id));
  }
}
