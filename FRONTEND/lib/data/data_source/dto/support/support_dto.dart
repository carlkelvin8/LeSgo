import 'package:json_annotation/json_annotation.dart';

part 'support_dto.g.dart';

@JsonSerializable()
class SupportTicketDto {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(defaultValue: 'Support request')
  final String subject;
  @JsonKey(defaultValue: '')
  final String description;
  @JsonKey(defaultValue: 'general_inquiry')
  final String category;
  @JsonKey(defaultValue: 'medium')
  final String priority;
  @JsonKey(defaultValue: 'open')
  final String status;
  @JsonKey(name: 'assigned_to')
  final int? assignedTo;
  @JsonKey(name: 'closed_at')
  final String? closedAt;
  @JsonKey(name: 'created_at', defaultValue: '')
  final String createdAt;
  @JsonKey(name: 'updated_at', defaultValue: '')
  final String updatedAt;

  SupportTicketDto({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicketDto.fromJson(Map<String, dynamic> json) {
    // Older servers return an incomplete, id-zero payload after a failed insert.
    // Never treat that response as a saved conversation.
    if (json['id'] is! num ||
        (json['id'] as num) <= 0 ||
        json['user_id'] is! num ||
        [
          'subject',
          'description',
          'category',
          'priority',
          'status',
          'created_at',
          'updated_at',
        ].any((key) => json[key] is! String)) {
      throw const FormatException('Invalid support conversation response');
    }
    return _$SupportTicketDtoFromJson(json);
  }

  Map<String, dynamic> toJson() => _$SupportTicketDtoToJson(this);
}

@JsonSerializable()
class CreateTicketDto {
  final String subject;
  final String description;
  final String category;
  final String priority;

  CreateTicketDto({
    required this.subject,
    required this.description,
    required this.category,
    this.priority = 'medium',
  });

  factory CreateTicketDto.fromJson(Map<String, dynamic> json) =>
      _$CreateTicketDtoFromJson(json);

  Map<String, dynamic> toJson() => {
    ..._$CreateTicketDtoToJson(this),
    'category': category == 'general' ? 'general_inquiry' : category,
  };
}

@JsonSerializable()
class TicketMessageDto {
  final List<String> attachments;
  final int id;
  @JsonKey(name: 'ticket_id')
  final int ticketId;
  @JsonKey(name: 'user_id')
  final int userId;
  final String message;
  @JsonKey(name: 'is_staff')
  final bool isStaff;
  @JsonKey(name: 'created_at')
  final String createdAt;

  TicketMessageDto({
    this.attachments = const [],
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.message,
    required this.isStaff,
    required this.createdAt,
  });

  factory TicketMessageDto.fromJson(Map<String, dynamic> json) =>
      _$TicketMessageDtoFromJson({
        ...json,
        'user_id': json['user_id'] ?? 0,
        'is_staff':
            json['is_staff'] ??
            (json['user'] is Map &&
                [
                  'admin',
                  'partner_admin',
                  'support',
                  'agent',
                ].contains(json['user']['role'])),
      });

  Map<String, dynamic> toJson() => _$TicketMessageDtoToJson(this);
}
