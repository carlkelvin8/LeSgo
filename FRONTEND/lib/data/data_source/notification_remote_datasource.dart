import 'package:injectable/injectable.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/notification/notification_dto.dart';

@lazySingleton
class NotificationRemoteDataSource {
  final DioClient _dioClient;

  NotificationRemoteDataSource(this._dioClient);

  Future<NotificationsResponseDto> fetchNotifications({
    bool unreadOnly = false,
    int page = 1,
  }) async {
    final response = await _dioClient.dio.get(
      ApiConstants.notifications,
      queryParameters: {
        'unread_only': unreadOnly,
        'page': page,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final rawList = body['data'] as List? ?? [];
    final notifications = rawList.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return NotificationDto(
        id: (map['id'] as num).toInt(),
        userId: (map['user_id'] as num?)?.toInt() ?? 0,
        type: map['type']?.toString() ?? 'system_alert',
        title: map['title']?.toString() ?? 'Notification',
        message: map['message']?.toString() ?? map['body']?.toString() ?? '',
        data: map['data'] is Map
            ? Map<String, dynamic>.from(map['data'] as Map)
            : null,
        isRead: map['is_read'] == true || map['read_at'] != null,
        readAt: map['read_at']?.toString(),
        createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      );
    }).toList();

    return NotificationsResponseDto(
      success: body['success'] == true,
      data: notifications,
      meta: body['meta'] is Map
          ? Map<String, dynamic>.from(body['meta'] as Map)
          : null,
    );
  }

  Future<int> fetchUnreadCount() async {
    final response =
        await _dioClient.dio.get(ApiConstants.notificationsUnreadCount);
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return (data['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(int notificationId) async {
    await _dioClient.dio.patch(
      ApiConstants.notificationMarkRead(notificationId),
    );
  }

  Future<void> markAllRead() async {
    await _dioClient.dio.post(ApiConstants.notificationsReadAll);
  }
}
