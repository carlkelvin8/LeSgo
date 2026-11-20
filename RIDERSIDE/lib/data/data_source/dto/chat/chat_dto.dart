import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/json_parsers.dart';

part 'chat_dto.g.dart';

@JsonSerializable()
class ConversationDto {
  @JsonKey(fromJson: parseIntOrStringStrict)
  final int id;
  @JsonKey(name: 'order_id', fromJson: parseIntOrString)
  final int? orderId;
  @JsonKey(name: 'customer_id', fromJson: parseIntOrString)
  final int? customerId;
  @JsonKey(name: 'driver_id', fromJson: parseIntOrString)
  final int? driverId;
  final String status;
  @JsonKey(name: 'last_message_at')
  final String? lastMessageAt;
  @JsonKey(name: 'created_at')
  final String createdAt;
  
  // Customer info
  final CustomerDto? customer;
  
  // Latest message
  @JsonKey(name: 'latest_message')
  final MessageDto? latestMessage;

  // Block state relative to the signed-in user
  @JsonKey(name: 'blocked_by_me', defaultValue: false)
  final bool blockedByMe;
  @JsonKey(name: 'can_message', defaultValue: true)
  final bool canMessage;

  ConversationDto({
    required this.id,
    this.orderId,
    this.customerId,
    this.driverId,
    required this.status,
    this.lastMessageAt,
    required this.createdAt,
    this.customer,
    this.latestMessage,
    this.blockedByMe = false,
    this.canMessage = true,
  });

  ConversationDto copyWithBlockState({
    required bool blockedByMe,
    required bool canMessage,
  }) =>
      ConversationDto(
        id: id,
        orderId: orderId,
        customerId: customerId,
        driverId: driverId,
        status: status,
        lastMessageAt: lastMessageAt,
        createdAt: createdAt,
        customer: customer,
        latestMessage: latestMessage,
        blockedByMe: blockedByMe,
        canMessage: canMessage,
      );

  factory ConversationDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationDtoToJson(this);
}

@JsonSerializable()
class CustomerDto {
  @JsonKey(fromJson: parseIntOrStringStrict)
  final int id;
  final String name;
  final String? email;
  @JsonKey(name: 'profile_photo_url')
  final String? profilePhotoUrl;

  CustomerDto({
    required this.id,
    required this.name,
    this.email,
    this.profilePhotoUrl,
  });

  factory CustomerDto.fromJson(Map<String, dynamic> json) =>
      _$CustomerDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerDtoToJson(this);
}

@JsonSerializable()
class MessageDto {
  @JsonKey(fromJson: parseIntOrStringStrict)
  final int id;
  @JsonKey(name: 'conversation_id', fromJson: parseIntOrStringStrict)
  final int conversationId;
  @JsonKey(name: 'sender_id', fromJson: parseIntOrStringStrict)
  final int senderId;
  @JsonKey(name: 'sender_type')
  final String senderType;
  @JsonKey(name: 'message_type')
  final String messageType;
  final String content;
  @JsonKey(name: 'is_system_message', fromJson: parseBool)
  final bool isSystemMessage;
  @JsonKey(name: 'read_at')
  final String? readAt;
  @JsonKey(name: 'created_at')
  final String createdAt;
  
  // Sender info
  final SenderDto? sender;

  MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.messageType,
    required this.content,
    required this.isSystemMessage,
    this.readAt,
    required this.createdAt,
    this.sender,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) =>
      _$MessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MessageDtoToJson(this);
}

@JsonSerializable()
class SenderDto {
  @JsonKey(fromJson: parseIntOrStringStrict)
  final int id;
  final String name;
  final String? email;
  final String role;
  @JsonKey(name: 'profile_photo_url')
  final String? profilePhotoUrl;

  SenderDto({
    required this.id,
    required this.name,
    this.email,
    required this.role,
    this.profilePhotoUrl,
  });

  factory SenderDto.fromJson(Map<String, dynamic> json) =>
      _$SenderDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SenderDtoToJson(this);
}

@JsonSerializable()
class SendMessageDto {
  @JsonKey(name: 'conversation_id', fromJson: parseIntOrStringStrict)
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
