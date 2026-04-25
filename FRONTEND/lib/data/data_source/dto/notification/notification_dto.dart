import 'package:json_annotation/json_annotation.dart';

part 'notification_dto.g.dart';

@JsonSerializable()
class NotificationDto {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'read_at')
  final String? readAt;
  @JsonKey(name: 'created_at')
  final String createdAt;

  NotificationDto({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationDtoToJson(this);
}

@JsonSerializable()
class NotificationsResponseDto {
  final bool success;
  final List<NotificationDto> data;
  final Map<String, dynamic>? meta;
  final Map<String, dynamic>? links;

  NotificationsResponseDto({
    required this.success,
    required this.data,
    this.meta,
    this.links,
  });

  factory NotificationsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationsResponseDtoToJson(this);
}

@JsonSerializable()
class UnreadCountResponseDto {
  final bool success;
  final UnreadCountDataDto data;

  UnreadCountResponseDto({
    required this.success,
    required this.data,
  });

  factory UnreadCountResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UnreadCountResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UnreadCountResponseDtoToJson(this);
}

@JsonSerializable()
class UnreadCountDataDto {
  @JsonKey(name: 'unread_count')
  final int unreadCount;

  UnreadCountDataDto({
    required this.unreadCount,
  });

  factory UnreadCountDataDto.fromJson(Map<String, dynamic> json) =>
      _$UnreadCountDataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UnreadCountDataDtoToJson(this);
}
