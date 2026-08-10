import 'package:json_annotation/json_annotation.dart';

part 'login_request_dto.g.dart';

@JsonSerializable()
class LoginRequestDto {
  final String email;
  final String password;
  @JsonKey(name: 'two_factor_code')
  final String? twoFactorCode;

  LoginRequestDto({
    required this.email,
    required this.password,
    this.twoFactorCode,
  });

  factory LoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestDtoToJson(this);
}
