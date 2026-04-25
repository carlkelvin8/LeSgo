import 'package:json_annotation/json_annotation.dart';
import 'chat_dto.dart';

part 'chat_response_dto.g.dart';

@JsonSerializable()
class ConversationsResponseDto {
  final bool success;
  final List<ConversationDto> data;

  ConversationsResponseDto({
    required this.success,
    required this.data,
  });

  factory ConversationsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationsResponseDtoToJson(this);
}

@JsonSerializable()
class ConversationResponseDto {
  final bool success;
  final ConversationDto data;

  ConversationResponseDto({
    required this.success,
    required this.data,
  });

  factory ConversationResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationResponseDtoToJson(this);
}

@JsonSerializable()
class MessagesResponseDto {
  final bool success;
  final List<MessageDto> data;

  MessagesResponseDto({
    required this.success,
    required this.data,
  });

  factory MessagesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MessagesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MessagesResponseDtoToJson(this);
}

@JsonSerializable()
class MessageResponseDto {
  final bool success;
  final MessageDto data;

  MessageResponseDto({
    required this.success,
    required this.data,
  });

  factory MessageResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MessageResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MessageResponseDtoToJson(this);
}
