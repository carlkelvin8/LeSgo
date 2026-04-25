import 'package:json_annotation/json_annotation.dart';

part 'update_user_request_dto.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateUserRequestDto {
  final String? name;

  @JsonKey(name: 'phone_number')
  final String? phone;

  @JsonKey(name: 'date_of_birth')
  final String? dateOfBirth;

  final String? gender;

  @JsonKey(name: 'profile_photo_url')
  final String? profilePhoto;

  @JsonKey(name: 'address_line1')
  final String? addressLine1;

  @JsonKey(name: 'address_line2')
  final String? addressLine2;

  UpdateUserRequestDto({
    this.name,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.profilePhoto,
    this.addressLine1,
    this.addressLine2,
  });

  factory UpdateUserRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateUserRequestDtoToJson(this);
}
