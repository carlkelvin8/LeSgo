import 'package:json_annotation/json_annotation.dart';

part 'register_driver_response_dto.g.dart';

@JsonSerializable()
class RegisterDriverResponseDto {
  final bool success;
  final String message;
  final String? token;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  @JsonKey(name: 'expires_in')
  final int? expiresIn;
  final RegisterDriverDataDto? data;

  RegisterDriverResponseDto({
    required this.success,
    required this.message,
    this.token,
    this.refreshToken,
    this.expiresIn,
    this.data,
  });

  factory RegisterDriverResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterDriverResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterDriverResponseDtoToJson(this);
}

@JsonSerializable()
class RegisterDriverDataDto {
  final UserDto? user;
  @JsonKey(name: 'driver_profile')
  final DriverProfileDto? driverProfile;

  RegisterDriverDataDto({
    this.user,
    this.driverProfile,
  });

  factory RegisterDriverDataDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterDriverDataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterDriverDataDtoToJson(this);
}

@JsonSerializable()
class UserDto {
  @JsonKey(name: 'registration_fee')
  final Map<String, dynamic>? registrationFee;
  final int id;
  final String name;
  final String email;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  final String role;

  UserDto({
    this.registrationFee,
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}

@JsonSerializable()
class DriverProfileDto {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String status;
  @JsonKey(name: 'license_number')
  final String? licenseNumber;
  final double rating;
  @JsonKey(name: 'total_trips')
  final int totalTrips;

  DriverProfileDto({
    required this.id,
    required this.userId,
    required this.status,
    this.licenseNumber,
    required this.rating,
    required this.totalTrips,
  });

  factory DriverProfileDto.fromJson(Map<String, dynamic> json) =>
      _$DriverProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DriverProfileDtoToJson(this);
}
