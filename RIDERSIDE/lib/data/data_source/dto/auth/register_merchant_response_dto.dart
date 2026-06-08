import 'package:json_annotation/json_annotation.dart';

part 'register_merchant_response_dto.g.dart';

@JsonSerializable()
class RegisterMerchantResponseDto {
  final bool success;
  final String message;
  final String? token;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  @JsonKey(name: 'expires_in')
  final int? expiresIn;
  final MerchantUserDto? user;

  RegisterMerchantResponseDto({
    required this.success,
    required this.message,
    this.token,
    this.refreshToken,
    this.expiresIn,
    this.user,
  });

  factory RegisterMerchantResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterMerchantResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterMerchantResponseDtoToJson(this);
}

@JsonSerializable()
class MerchantUserDto {
  final int id;
  final String name;
  final String email;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  final String role;
  @JsonKey(name: 'partner_id')
  final int? partnerId;

  MerchantUserDto({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.partnerId,
  });

  factory MerchantUserDto.fromJson(Map<String, dynamic> json) =>
      _$MerchantUserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MerchantUserDtoToJson(this);
}
