import 'package:json_annotation/json_annotation.dart';

part 'register_driver_request_dto.g.dart';

@JsonSerializable()
class RegisterDriverRequestDto {
  final String name;
  final String email;
  @JsonKey(name: 'phone_number')
  final String phoneNumber;
  final String password;
  @JsonKey(name: 'password_confirmation')
  final String passwordConfirmation;
  @JsonKey(name: 'license_number')
  final String licenseNumber;
  @JsonKey(name: 'license_expiry_date')
  final String? licenseExpiryDate;
  @JsonKey(name: 'last_latitude')
  final double? lastLatitude;
  @JsonKey(name: 'last_longitude')
  final double? lastLongitude;
  @JsonKey(name: 'package_tier')
  final String? packageTier;

  RegisterDriverRequestDto({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.passwordConfirmation,
    required this.licenseNumber,
    this.licenseExpiryDate,
    this.lastLatitude,
    this.lastLongitude,
    this.packageTier,
  });

  factory RegisterDriverRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterDriverRequestDtoFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$RegisterDriverRequestDtoToJson(this);
    // Remove null values so backend doesn't get confused
    json.removeWhere((key, value) => value == null);
    return json;
  }
}
