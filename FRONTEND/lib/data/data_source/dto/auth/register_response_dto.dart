import 'package:json_annotation/json_annotation.dart';
import '../user/user_dto.dart';

part 'register_response_dto.g.dart';

@JsonSerializable()
class RegisterResponseDto {
  final bool success;
  final String message;
  final UserDto? user;
  final String? token;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  @JsonKey(name: 'token_type')
  final String? tokenType;
  @JsonKey(name: 'expires_at')
  final String? expiresAt;

  const RegisterResponseDto({
    required this.success,
    required this.message,
    this.user,
    this.token,
    this.refreshToken,
    this.tokenType,
    this.expiresAt,
  });

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterResponseDtoToJson(this);
}