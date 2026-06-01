import 'package:json_annotation/json_annotation.dart';

part 'register_merchant_request_dto.g.dart';

@JsonSerializable()
class RegisterMerchantRequestDto {
  final String name;
  final String email;
  final String? phone;
  final String password;
  @JsonKey(name: 'password_confirmation')
  final String passwordConfirmation;
  final String role;
  @JsonKey(name: 'restaurant_name')
  final String restaurantName;
  final String? address;
  @JsonKey(name: 'zip_code')
  final String? zipCode;
  @JsonKey(name: 'terms_accepted')
  final bool termsAccepted;
  @JsonKey(name: 'privacy_accepted')
  final bool privacyAccepted;
  @JsonKey(name: 'selfie_path')
  final String? selfiePath;
  @JsonKey(name: 'valid_id_path')
  final String? validIdPath;
  @JsonKey(name: 'digital_signature_path')
  final String? digitalSignaturePath;
  @JsonKey(name: 'barangay_permit_path')
  final String? barangayPermitPath;
  @JsonKey(name: 'mayors_permit_path')
  final String? mayorsPermitPath;
  @JsonKey(name: 'dti_permit_path')
  final String? dtiPermitPath;

  RegisterMerchantRequestDto({
    required this.name,
    required this.email,
    this.phone,
    required this.password,
    required this.passwordConfirmation,
    this.role = 'partner_admin',
    required this.restaurantName,
    this.address,
    this.zipCode,
    this.termsAccepted = true,
    this.privacyAccepted = true,
    this.selfiePath,
    this.validIdPath,
    this.digitalSignaturePath,
    this.barangayPermitPath,
    this.mayorsPermitPath,
    this.dtiPermitPath,
  });

  factory RegisterMerchantRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterMerchantRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterMerchantRequestDtoToJson(this);
}
