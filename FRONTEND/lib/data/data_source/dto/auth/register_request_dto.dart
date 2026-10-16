import 'package:json_annotation/json_annotation.dart';

part 'register_request_dto.g.dart';

@JsonSerializable()
class RegisterRequestDto {
  final String name;
  final String email;
  final String phone;
  @JsonKey(name: 'phone_verification_token', includeIfNull: false)
  final String? phoneVerificationToken;
  final String password;
  @JsonKey(name: 'password_confirmation')
  final String passwordConfirmation;
  @JsonKey(name: 'date_of_birth')
  final String? dateOfBirth;
  @JsonKey(name: 'referral_code')
  final String? referralCode;
  @JsonKey(name: 'address_line_1')
  final String? addressLine1;
  @JsonKey(name: 'address_line_2')
  final String? addressLine2;
  @JsonKey(name: 'is_default')
  final bool isDefault;
  final String? city;
  final String? province;
  @JsonKey(name: 'zip_code')
  final String? zipCode;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'terms_accepted')
  final bool termsAccepted;
  @JsonKey(name: 'privacy_accepted')
  final bool privacyAccepted;
  @JsonKey(name: 'id_type')
  final String idType;
  @JsonKey(name: 'id_number')
  final String idNumber;
  final String? role;

  const RegisterRequestDto({
    required this.name,
    required this.email,
    required this.phone,
    this.phoneVerificationToken,
    required this.password,
    required this.passwordConfirmation,
    this.dateOfBirth,
    this.referralCode,
    this.addressLine1,
    this.addressLine2,
    this.isDefault = false,
    this.city,
    this.province,
    this.zipCode,
    this.latitude,
    this.longitude,
    required this.termsAccepted,
    required this.privacyAccepted,
    required this.idType,
    required this.idNumber,
    this.role,
  });

  factory RegisterRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestDtoToJson(this);
}
