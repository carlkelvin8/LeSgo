// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationDto _$NotificationDtoFromJson(Map<String, dynamic> json) =>
    NotificationDto(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$NotificationDtoToJson(NotificationDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'type': instance.type,
      'title': instance.title,
      'message': instance.message,
      'data': instance.data,
      'is_read': instance.isRead,
      'read_at': instance.readAt,
      'created_at': instance.createdAt,
    };

NotificationsResponseDto _$NotificationsResponseDtoFromJson(
  Map<String, dynamic> json,
) => NotificationsResponseDto(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => NotificationDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] as Map<String, dynamic>?,
  links: json['links'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$NotificationsResponseDtoToJson(
  NotificationsResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'meta': instance.meta,
  'links': instance.links,
};

UnreadCountResponseDto _$UnreadCountResponseDtoFromJson(
  Map<String, dynamic> json,
) => UnreadCountResponseDto(
  success: json['success'] as bool,
  data: UnreadCountDataDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UnreadCountResponseDtoToJson(
  UnreadCountResponseDto instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

UnreadCountDataDto _$UnreadCountDataDtoFromJson(Map<String, dynamic> json) =>
    UnreadCountDataDto(unreadCount: (json['unread_count'] as num).toInt());

Map<String, dynamic> _$UnreadCountDataDtoToJson(UnreadCountDataDto instance) =>
    <String, dynamic>{'unread_count': instance.unreadCount};
