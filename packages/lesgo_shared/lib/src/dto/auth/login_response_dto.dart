import 'package:json_annotation/json_annotation.dart';

part 'login_response_dto.g.dart';

@JsonSerializable()
class LoginResponseDto {
  final bool success;
  final String? message;
  final String? token;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  final Map<String, dynamic>? user;
  @JsonKey(name: 'is_new_user')
  final bool? isNewUser;

  const LoginResponseDto({
    required this.success,
    this.message,
    this.token,
    this.refreshToken,
    this.user,
    this.isNewUser,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseDtoToJson(this);
}
