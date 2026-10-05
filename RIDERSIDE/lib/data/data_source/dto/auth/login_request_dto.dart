import 'package:json_annotation/json_annotation.dart';

part 'login_request_dto.g.dart';

@JsonSerializable()
class LoginRequestDto {
  final String email;
  final String password;
  @JsonKey(name: 'device_name')
  final String? deviceName;

  LoginRequestDto({
    required this.email,
    required this.password,
    this.deviceName = 'mobile-app',
  });

  factory LoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestDtoToJson(this);
}
