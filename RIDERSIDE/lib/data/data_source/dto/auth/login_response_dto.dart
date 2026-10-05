import 'package:json_annotation/json_annotation.dart';

part 'login_response_dto.g.dart';

@JsonSerializable()
class LoginResponseDto {
  final bool success;
  final String message;
  final String? token;
  @JsonKey(name: 'expires_in')
  final int? expiresIn;
  final LoginUserDto? user;

  LoginResponseDto({
    required this.success,
    required this.message,
    this.token,
    this.expiresIn,
    this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseDtoToJson(this);
}

@JsonSerializable()
class LoginUserDto {
  final int id;
  final String name;
  final String email;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  final String role;
  @JsonKey(name: 'driver_profile')
  final Map<String, dynamic>? driverProfile;
  @JsonKey(name: 'partner_id')
  final int? partnerId;

  LoginUserDto({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.driverProfile,
    this.partnerId,
  });

  factory LoginUserDto.fromJson(Map<String, dynamic> json) =>
      _$LoginUserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginUserDtoToJson(this);
}
