import 'package:json_annotation/json_annotation.dart';
import '../user/user_dto.dart';

part 'login_response_dto.g.dart';

@JsonSerializable()
class LoginResponseDto {
  final bool success;
  final String message;
  final UserDto? user;
  final String? token;
  @JsonKey(name: 'token_type')
  final String? tokenType;
  @JsonKey(name: 'expires_at')
  final String? expiresAt;

  const LoginResponseDto({
    required this.success,
    required this.message,
    this.user,
    this.token,
    this.tokenType,
    this.expiresAt,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseDtoToJson(this);
}