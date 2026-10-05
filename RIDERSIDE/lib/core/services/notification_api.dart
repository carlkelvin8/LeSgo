import '../constants/api_constants.dart';
import '../di/injection.dart';
import '../network/dio_client.dart';

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'system_alert',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? json['body']?.toString() ?? '',
      isRead: json['is_read'] == true || json['read_at'] != null,
      createdAt: json['created_at']?.toString() ?? '',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
    );
  }
}

class NotificationApi {
  NotificationApi._();

  static final _dio = getIt<DioClient>().dio;

  static Future<List<AppNotification>> fetchNotifications({
    bool unreadOnly = false,
    int page = 1,
  }) async {
    final res = await _dio.get(
      ApiConstants.notifications,
      queryParameters: {
        'unread_only': unreadOnly,
        'page': page,
      },
    );
    final body = res.data as Map<String, dynamic>;
    final rawList = body['data'] as List? ?? [];
    return rawList
        .whereType<Map>()
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<int> fetchUnreadCount() async {
    final res = await _dio.get(ApiConstants.notificationsUnreadCount);
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return (data['unread_count'] as num?)?.toInt() ?? 0;
  }

  static Future<void> markRead(int notificationId) async {
    await _dio.patch(ApiConstants.notificationMarkRead(notificationId));
  }

  static Future<void> markAllRead() async {
    await _dio.post(ApiConstants.notificationsReadAll);
  }
}
