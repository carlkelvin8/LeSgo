// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageDto _$MessageDtoFromJson(Map<String, dynamic> json) => MessageDto(
  id: (json['id'] as num).toInt(),
  conversationId: (json['conversation_id'] as num).toInt(),
  senderId: (json['sender_id'] as num).toInt(),
  senderType: json['sender_type'] as String,
  content: json['content'] as String,
  messageType: json['message_type'] as String? ?? 'text',
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: json['created_at'] as String,
  readAt: json['read_at'] as String?,
  isSystemMessage: json['is_system_message'] as bool? ?? false,
);

Map<String, dynamic> _$MessageDtoToJson(MessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversation_id': instance.conversationId,
      'sender_id': instance.senderId,
      'sender_type': instance.senderType,
      'content': instance.content,
      'message_type': instance.messageType,
      'metadata': instance.metadata,
      'created_at': instance.createdAt,
      'read_at': instance.readAt,
      'is_system_message': instance.isSystemMessage,
    };

ConversationDto _$ConversationDtoFromJson(Map<String, dynamic> json) =>
    ConversationDto(
      id: (json['id'] as num).toInt(),
      orderId: (json['order_id'] as num).toInt(),
      customerId: (json['customer_id'] as num).toInt(),
      driverId: (json['driver_id'] as num?)?.toInt(),
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      endedAt: json['ended_at'] as String?,
      lastMessage: json['latest_message'] == null
          ? null
          : MessageDto.fromJson(json['latest_message'] as Map<String, dynamic>),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ConversationDtoToJson(ConversationDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'customer_id': instance.customerId,
      'driver_id': instance.driverId,
      'status': instance.status,
      'created_at': instance.createdAt,
      'ended_at': instance.endedAt,
      'latest_message': instance.lastMessage,
      'unread_count': instance.unreadCount,
    };

SendMessageRequestDto _$SendMessageRequestDtoFromJson(
  Map<String, dynamic> json,
) => SendMessageRequestDto(
  message: json['message'] as String,
  messageType: json['message_type'] as String? ?? 'text',
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$SendMessageRequestDtoToJson(
  SendMessageRequestDto instance,
) => <String, dynamic>{
  'message': instance.message,
  'message_type': instance.messageType,
  'metadata': instance.metadata,
};
