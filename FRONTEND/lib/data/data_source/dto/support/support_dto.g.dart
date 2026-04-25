// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportTicketDto _$SupportTicketDtoFromJson(Map<String, dynamic> json) =>
    SupportTicketDto(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      subject: json['subject'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      assignedTo: (json['assigned_to'] as num?)?.toInt(),
      closedAt: json['closed_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$SupportTicketDtoToJson(SupportTicketDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'subject': instance.subject,
      'description': instance.description,
      'category': instance.category,
      'priority': instance.priority,
      'status': instance.status,
      'assigned_to': instance.assignedTo,
      'closed_at': instance.closedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

CreateTicketDto _$CreateTicketDtoFromJson(Map<String, dynamic> json) =>
    CreateTicketDto(
      subject: json['subject'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String? ?? 'medium',
    );

Map<String, dynamic> _$CreateTicketDtoToJson(CreateTicketDto instance) =>
    <String, dynamic>{
      'subject': instance.subject,
      'description': instance.description,
      'category': instance.category,
      'priority': instance.priority,
    };

TicketMessageDto _$TicketMessageDtoFromJson(Map<String, dynamic> json) =>
    TicketMessageDto(
      id: (json['id'] as num).toInt(),
      ticketId: (json['ticket_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      message: json['message'] as String,
      isStaff: json['is_staff'] as bool,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$TicketMessageDtoToJson(TicketMessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticket_id': instance.ticketId,
      'user_id': instance.userId,
      'message': instance.message,
      'is_staff': instance.isStaff,
      'created_at': instance.createdAt,
    };
