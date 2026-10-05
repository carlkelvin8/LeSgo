import 'package:json_annotation/json_annotation.dart';

part 'chat_dto.g.dart';

/// Safely parses a value that may be int, num, or String into int?
int? _parseIntOrString(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Safely parses a value that may be int, num, or String into int (non-nullable)
int _parseIntOrStringStrict(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

@JsonSerializable()
class ConversationDto {
  @JsonKey(fromJson: _parseIntOrStringStrict)
  final int id;
  @JsonKey(name: 'order_id', fromJson: _parseIntOrString)
  final int? orderId;
  @JsonKey(name: 'participant_ids')
  final List<int> participantIds;
  @JsonKey(name: 'last_message')
  final String? lastMessage;
  @JsonKey(name: 'last_message_at')
  final String? lastMessageAt;
  @JsonKey(name: 'unread_count', fromJson: _parseIntOrStringStrict)
  final int unreadCount;
  @JsonKey(name: 'created_at')
  final String createdAt;

  ConversationDto({
    required this.id,
    this.orderId,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationDtoToJson(this);
}

@JsonSerializable()
class MessageDto {
  @JsonKey(fromJson: _parseIntOrStringStrict)
  final int id;
  @JsonKey(name: 'conversation_id', fromJson: _parseIntOrStringStrict)
  final int conversationId;
  @JsonKey(name: 'sender_id', fromJson: _parseIntOrStringStrict)
  final int senderId;
  final String message;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'created_at')
  final String createdAt;
  
  // Optional sender info
  @JsonKey(name: 'sender_name')
  final String? senderName;
  @JsonKey(name: 'sender_photo')
  final String? senderPhoto;

  MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.senderPhoto,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) =>
      _$MessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MessageDtoToJson(this);
}

@JsonSerializable()
class SendMessageDto {
  @JsonKey(name: 'conversation_id', fromJson: _parseIntOrStringStrict)
  final int conversationId;
  final String message;

  SendMessageDto({
    required this.conversationId,
    required this.message,
  });

  factory SendMessageDto.fromJson(Map<String, dynamic> json) =>
      _$SendMessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SendMessageDtoToJson(this);
}
