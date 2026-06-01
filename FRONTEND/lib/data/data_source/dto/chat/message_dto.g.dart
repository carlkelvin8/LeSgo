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
      serviceName: json['service_name'] as String?,
      serviceId: (json['service_id'] as num?)?.toInt(),
      serviceType: json['service_type'] as String?,
      order: json['order'] as Map<String, dynamic>?,
      customer: json['customer'] == null
          ? null
          : UserInfoDto.fromJson(json['customer'] as Map<String, dynamic>),
      driver: json['driver'] == null
          ? null
          : UserInfoDto.fromJson(json['driver'] as Map<String, dynamic>),
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
      'service_name': instance.serviceName,
      'service_id': instance.serviceId,
      'service_type': instance.serviceType,
      'order': instance.order,
      'customer': instance.customer,
      'driver': instance.driver,
    };

UserInfoDto _$UserInfoDtoFromJson(Map<String, dynamic> json) => UserInfoDto(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String,
  profilePhotoUrl: json['profile_photo_url'] as String?,
);

Map<String, dynamic> _$UserInfoDtoToJson(UserInfoDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'profile_photo_url': instance.profilePhotoUrl,
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
