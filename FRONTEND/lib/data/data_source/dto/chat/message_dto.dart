import 'package:json_annotation/json_annotation.dart';

part 'message_dto.g.dart';

@JsonSerializable()
class MessageDto {
  final int id;
  @JsonKey(name: 'conversation_id')
  final int conversationId;
  @JsonKey(name: 'sender_id')
  final int senderId;
  @JsonKey(name: 'sender_type')
  final String senderType; // 'customer', 'driver', 'system'
  final String content; // Backend uses 'content' not 'message'
  @JsonKey(name: 'message_type')
  final String? messageType; // 'text', 'image', 'location', 'system'
  final Map<String, dynamic>? metadata; // JSON object for additional data
  @JsonKey(name: 'created_at')
  final String createdAt; // Backend returns string dates
  @JsonKey(name: 'read_at')
  final String? readAt;
  @JsonKey(name: 'is_system_message')
  final bool isSystemMessage;

  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.content,
    this.messageType = 'text',
    this.metadata,
    required this.createdAt,
    this.readAt,
    this.isSystemMessage = false,
  });

  // Getter for compatibility with existing chat widgets
  String get message => content;
  bool get isRead => readAt != null;

  factory MessageDto.fromJson(Map<String, dynamic> json) => _$MessageDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MessageDtoToJson(this);

  MessageDto copyWith({
    int? id,
    int? conversationId,
    int? senderId,
    String? senderType,
    String? content,
    String? messageType,
    Map<String, dynamic>? metadata,
    String? createdAt,
    String? readAt,
    bool? isSystemMessage,
  }) {
    return MessageDto(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
    );
  }
}

@JsonSerializable()
class ConversationDto {
  final int id;
  @JsonKey(name: 'order_id')
  final int orderId;
  @JsonKey(name: 'customer_id')
  final int customerId;
  @JsonKey(name: 'driver_id')
  final int? driverId;
  final String status; // 'active', 'ended'
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'ended_at')
  final String? endedAt;
  @JsonKey(name: 'latest_message')
  final MessageDto? lastMessage;
  @JsonKey(name: 'unread_count')
  final int unreadCount;
  
  // Driver and customer information
  final UserInfoDto? customer;
  final UserInfoDto? driver;

  const ConversationDto({
    required this.id,
    required this.orderId,
    required this.customerId,
    this.driverId,
    required this.status,
    required this.createdAt,
    this.endedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.customer,
    this.driver,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) => _$ConversationDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationDtoToJson(this);
}

@JsonSerializable()
class UserInfoDto {
  final int id;
  final String name;
  final String email;
  @JsonKey(name: 'profile_photo_url')
  final String? profilePhotoUrl;

  const UserInfoDto({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhotoUrl,
  });

  factory UserInfoDto.fromJson(Map<String, dynamic> json) => _$UserInfoDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoDtoToJson(this);
}

@JsonSerializable()
class SendMessageRequestDto {
  final String message;
  @JsonKey(name: 'message_type')
  final String messageType;
  final Map<String, dynamic>? metadata;

  const SendMessageRequestDto({
    required this.message,
    this.messageType = 'text',
    this.metadata,
  });

  factory SendMessageRequestDto.fromJson(Map<String, dynamic> json) => _$SendMessageRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SendMessageRequestDtoToJson(this);
}