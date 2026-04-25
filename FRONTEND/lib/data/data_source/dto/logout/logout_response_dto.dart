import 'package:json_annotation/json_annotation.dart';

part 'logout_response_dto.g.dart';

@JsonSerializable()
class LogoutResponseDto {
  final bool success;
  final String message;

  LogoutResponseDto({required this.success, required this.message});

  factory LogoutResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LogoutResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LogoutResponseDtoToJson(this);

  factory LogoutResponseDto.withError(String errorMessage) {
    return LogoutResponseDto(success: false, message: errorMessage);
  }
}
