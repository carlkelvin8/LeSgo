// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationDto _$ConversationDtoFromJson(Map<String, dynamic> json) =>
    ConversationDto(
      id: _parseIntOrStringStrict(json['id']),
      orderId: _parseIntOrString(json['order_id']),
      participantIds: (json['participant_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] as String?,
      unreadCount: _parseIntOrStringStrict(json['unread_count']),
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$ConversationDtoToJson(ConversationDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'participant_ids': instance.participantIds,
      'last_message': instance.lastMessage,
      'last_message_at': instance.lastMessageAt,
      'unread_count': instance.unreadCount,
      'created_at': instance.createdAt,
    };

MessageDto _$MessageDtoFromJson(Map<String, dynamic> json) => MessageDto(
  id: _parseIntOrStringStrict(json['id']),
  conversationId: _parseIntOrStringStrict(json['conversation_id']),
  senderId: _parseIntOrStringStrict(json['sender_id']),
  message: json['message'] as String,
  isRead: json['is_read'] as bool,
  createdAt: json['created_at'] as String,
  senderName: json['sender_name'] as String?,
  senderPhoto: json['sender_photo'] as String?,
);

Map<String, dynamic> _$MessageDtoToJson(MessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversation_id': instance.conversationId,
      'sender_id': instance.senderId,
      'message': instance.message,
      'is_read': instance.isRead,
      'created_at': instance.createdAt,
      'sender_name': instance.senderName,
      'sender_photo': instance.senderPhoto,
    };

SendMessageDto _$SendMessageDtoFromJson(Map<String, dynamic> json) =>
    SendMessageDto(
      conversationId: _parseIntOrStringStrict(json['conversation_id']),
      message: json['message'] as String,
    );

Map<String, dynamic> _$SendMessageDtoToJson(SendMessageDto instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'message': instance.message,
    };
