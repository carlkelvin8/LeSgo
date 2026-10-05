import 'package:json_annotation/json_annotation.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class SharedUserDto {
  final int? id;
  final String? name;
  final String? email;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  final String? role;
  @JsonKey(name: 'profile_photo_url')
  final String? profilePhotoUrl;
  @JsonKey(name: 'email_verified_at')
  final String? emailVerifiedAt;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  const SharedUserDto({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.role,
    this.profilePhotoUrl,
    this.emailVerifiedAt,
    this.createdAt,
  });

  factory SharedUserDto.fromJson(Map<String, dynamic> json) =>
      _$SharedUserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SharedUserDtoToJson(this);
}
