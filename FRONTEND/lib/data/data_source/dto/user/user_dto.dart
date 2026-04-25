import 'package:json_annotation/json_annotation.dart';

part 'user_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class UserDto {
  final UserPayloadDto? user;
  final String? token;
  final String? message;
  final bool? success;

  UserDto({
    this.user,
    this.token,
    this.message,
    this.success,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);

  String get id => user?.id.toString() ?? '';

  String get email => user?.email ?? '';

  String get name => user?.name ?? '';

  factory UserDto.withError(String errorMessage) {
    return UserDto(
      user: null,
      token: null,
      message: errorMessage,
      success: false,
    );
  }
}

@JsonSerializable()
class UserPayloadDto {
  final int? id;
  final String? name;
  final String? email;

  UserPayloadDto({this.id, this.name, this.email});

  factory UserPayloadDto.fromJson(Map<String, dynamic> json) =>
      _$UserPayloadDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserPayloadDtoToJson(this);
}
