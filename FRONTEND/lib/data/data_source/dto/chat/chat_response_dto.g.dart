// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationsResponseDto _$ConversationsResponseDtoFromJson(
  Map<String, dynamic> json,
) => ConversationsResponseDto(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => ConversationDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ConversationsResponseDtoToJson(
  ConversationsResponseDto instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

ConversationResponseDto _$ConversationResponseDtoFromJson(
  Map<String, dynamic> json,
) => ConversationResponseDto(
  success: json['success'] as bool,
  data: ConversationDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ConversationResponseDtoToJson(
  ConversationResponseDto instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

MessagesResponseDto _$MessagesResponseDtoFromJson(Map<String, dynamic> json) =>
    MessagesResponseDto(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => MessageDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MessagesResponseDtoToJson(
  MessagesResponseDto instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

MessageResponseDto _$MessageResponseDtoFromJson(Map<String, dynamic> json) =>
    MessageResponseDto(
      success: json['success'] as bool,
      data: MessageDto.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MessageResponseDtoToJson(MessageResponseDto instance) =>
    <String, dynamic>{'success': instance.success, 'data': instance.data};
