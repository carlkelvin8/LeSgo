import 'package:json_annotation/json_annotation.dart';

part 'message_dto.g.dart';

@JsonSerializable()
class SharedMessageDto {
  final int? id;
  @JsonKey(name: 'conversation_id')
  final int? conversationId;
  @JsonKey(name: 'sender_id')
  final int? senderId;
  @JsonKey(name: 'sender_type')
  final String? senderType;
  final String? message;
  final String? type;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'read_at')
  final String? readAt;

  const SharedMessageDto({
    this.id,
    this.conversationId,
    this.senderId,
    this.senderType,
    this.message,
    this.type,
    this.createdAt,
    this.readAt,
  });

  factory SharedMessageDto.fromJson(Map<String, dynamic> json) =>
      _$SharedMessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SharedMessageDtoToJson(this);
}
