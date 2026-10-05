// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationDto _$ConversationDtoFromJson(Map<String, dynamic> json) =>
    ConversationDto(
      id: parseIntOrStringStrict(json['id']),
      orderId: parseIntOrString(json['order_id']),
      customerId: parseIntOrString(json['customer_id']),
      driverId: parseIntOrString(json['driver_id']),
      status: json['status'] as String,
      lastMessageAt: json['last_message_at'] as String?,
      createdAt: json['created_at'] as String,
      customer: json['customer'] == null
          ? null
          : CustomerDto.fromJson(json['customer'] as Map<String, dynamic>),
      latestMessage: json['latest_message'] == null
          ? null
          : MessageDto.fromJson(
              json['latest_message'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ConversationDtoToJson(ConversationDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'customer_id': instance.customerId,
      'driver_id': instance.driverId,
      'status': instance.status,
      'last_message_at': instance.lastMessageAt,
      'created_at': instance.createdAt,
      'customer': instance.customer,
      'latest_message': instance.latestMessage,
    };

CustomerDto _$CustomerDtoFromJson(Map<String, dynamic> json) => CustomerDto(
      id: parseIntOrStringStrict(json['id']),
      name: json['name'] as String,
      email: json['email'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );

Map<String, dynamic> _$CustomerDtoToJson(CustomerDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'profile_photo_url': instance.profilePhotoUrl,
    };

MessageDto _$MessageDtoFromJson(Map<String, dynamic> json) => MessageDto(
      id: parseIntOrStringStrict(json['id']),
      conversationId: parseIntOrStringStrict(json['conversation_id']),
      senderId: parseIntOrStringStrict(json['sender_id']),
      senderType: json['sender_type'] as String,
      messageType: json['message_type'] as String,
      content: json['content'] as String,
      isSystemMessage: parseBool(json['is_system_message']),
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String,
      sender: json['sender'] == null
          ? null
          : SenderDto.fromJson(json['sender'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MessageDtoToJson(MessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversation_id': instance.conversationId,
      'sender_id': instance.senderId,
      'sender_type': instance.senderType,
      'message_type': instance.messageType,
      'content': instance.content,
      'is_system_message': instance.isSystemMessage,
      'read_at': instance.readAt,
      'created_at': instance.createdAt,
      'sender': instance.sender,
    };

SenderDto _$SenderDtoFromJson(Map<String, dynamic> json) => SenderDto(
      id: parseIntOrStringStrict(json['id']),
      name: json['name'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );

Map<String, dynamic> _$SenderDtoToJson(SenderDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
      'profile_photo_url': instance.profilePhotoUrl,
    };

SendMessageDto _$SendMessageDtoFromJson(Map<String, dynamic> json) =>
    SendMessageDto(
      conversationId: parseIntOrStringStrict(json['conversation_id']),
      message: json['message'] as String,
    );

Map<String, dynamic> _$SendMessageDtoToJson(SendMessageDto instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'message': instance.message,
    };
