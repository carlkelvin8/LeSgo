import 'package:json_annotation/json_annotation.dart';

part 'user_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class UserDto {
  final UserPayloadDto? user;
  final String? token;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  final String? message;
  final bool? success;
  @JsonKey(name: 'two_factor_required')
  final bool twoFactorRequired;

  UserDto({
    this.user,
    this.token,
    this.refreshToken,
    this.message,
    this.success,
    this.twoFactorRequired = false,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);

  String get id => user?.id.toString() ?? '';

  String get email => user?.email ?? '';

  String get name => user?.name ?? '';

  String? get role => user?.role;

  factory UserDto.withError(String errorMessage) {
    return UserDto(
      user: null,
      token: null,
      refreshToken: null,
      message: errorMessage,
      success: false,
      twoFactorRequired: false,
    );
  }
}

@JsonSerializable()
class UserPayloadDto {
  final int? id;
  final String? name;
  final String? email;
  final String? role;

  UserPayloadDto({this.id, this.name, this.email, this.role});

  factory UserPayloadDto.fromJson(Map<String, dynamic> json) =>
      _$UserPayloadDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserPayloadDtoToJson(this);
}
