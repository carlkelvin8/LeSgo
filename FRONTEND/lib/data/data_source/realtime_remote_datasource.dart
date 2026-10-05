import 'package:injectable/injectable.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';

@lazySingleton
class RealtimeRemoteDataSource {
  final DioClient _dioClient;

  RealtimeRemoteDataSource(this._dioClient);

  Future<Map<String, dynamic>> fetchConfig() async {
    final response = await _dioClient.dio.get(ApiConstants.realtimeConfig);
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    final websocket = data['websocket'];
    if (websocket is Map) {
      return Map<String, dynamic>.from(websocket);
    }
    return {'enabled': false};
  }

  Future<Map<String, dynamic>> connect({String platform = 'mobile'}) async {
    final response = await _dioClient.dio.post(
      ApiConstants.realtimeConnect,
      data: {'platform': platform, 'device_name': 'lesgo_customer'},
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<void> ping(String connectionId) async {
    await _dioClient.dio.post(
      ApiConstants.realtimePing,
      data: {'connection_id': connectionId},
    );
  }

  Future<void> disconnect(String connectionId) async {
    await _dioClient.dio.post(
      ApiConstants.realtimeDisconnect,
      data: {'connection_id': connectionId},
    );
  }

  Future<Map<String, dynamic>> authorizeChannel({
    required String socketId,
    required String channelName,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.broadcastingAuth,
      data: {
        'socket_id': socketId,
        'channel_name': channelName,
      },
    );
    if (response.data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(response.data);
    }
    return {'auth': response.data?.toString() ?? ''};
  }

  Future<List<Map<String, dynamic>>> fetchNotifications({
    bool unreadOnly = false,
    String? type,
    int perPage = 20,
  }) async {
    final response = await _dioClient.dio.get(
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
      return raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  Future<void> markNotificationRead(int notificationId) async {
    await _dioClient.dio.post(
      ApiConstants.realtimeNotificationRead(notificationId),
    );
  }
}
