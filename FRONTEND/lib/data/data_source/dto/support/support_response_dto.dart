import 'package:json_annotation/json_annotation.dart';
import 'support_dto.dart';

part 'support_response_dto.g.dart';

@JsonSerializable()
class SupportTicketsResponseDto {
  final bool success;
  final List<SupportTicketDto> data;

  SupportTicketsResponseDto({
    required this.success,
    required this.data,
  });

  factory SupportTicketsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SupportTicketsResponseDtoToJson(this);
}

@JsonSerializable()
class SupportTicketResponseDto {
  final bool success;
  final String? message;
  final SupportTicketDto data;

  SupportTicketResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory SupportTicketResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SupportTicketResponseDtoToJson(this);
}

@JsonSerializable()
class TicketMessagesResponseDto {
  final bool success;
  final List<TicketMessageDto> data;

  TicketMessagesResponseDto({
    required this.success,
    required this.data,
  });

  factory TicketMessagesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TicketMessagesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TicketMessagesResponseDtoToJson(this);
}
