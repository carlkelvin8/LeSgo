import 'package:json_annotation/json_annotation.dart';
import 'user_profile_dto.dart';

part 'user_response_dto.g.dart';

@JsonSerializable()
class UserResponseDto {
  final bool success;
  final String? message;
  @JsonKey(name: 'user')
  final UserProfileDto? data;

  UserResponseDto({
    required this.success,
    this.message,
    this.data,
  });

  factory UserResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UserResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserResponseDtoToJson(this);
}
