import 'package:json_annotation/json_annotation.dart';
import '../user/user_dto.dart';

part 'auth_response_dto.g.dart';

@JsonSerializable()
class AuthResponseDto {
  final bool success;
  final String message;
  final String? token;
  final UserDto? user;

  AuthResponseDto({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseDtoToJson(this);
}
