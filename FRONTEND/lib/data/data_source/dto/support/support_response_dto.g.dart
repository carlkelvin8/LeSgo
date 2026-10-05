// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportTicketsResponseDto _$SupportTicketsResponseDtoFromJson(
  Map<String, dynamic> json,
) => SupportTicketsResponseDto(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => SupportTicketDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SupportTicketsResponseDtoToJson(
  SupportTicketsResponseDto instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

SupportTicketResponseDto _$SupportTicketResponseDtoFromJson(
  Map<String, dynamic> json,
) => SupportTicketResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: SupportTicketDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SupportTicketResponseDtoToJson(
  SupportTicketResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

TicketMessagesResponseDto _$TicketMessagesResponseDtoFromJson(
  Map<String, dynamic> json,
) => TicketMessagesResponseDto(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => TicketMessageDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TicketMessagesResponseDtoToJson(
  TicketMessagesResponseDto instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};
