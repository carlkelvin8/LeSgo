import 'package:json_annotation/json_annotation.dart';

part 'user_profile_dto.g.dart';

@JsonSerializable()
class UserProfileDto {
  final int id;
  final String name;
  final String email;
  
  @JsonKey(name: 'phone_number')
  final String? phone;
  
  @JsonKey(name: 'date_of_birth')
  final String? dateOfBirth;
  
  @JsonKey(name: 'address_line1')
  final String? addressLine1;
  
  @JsonKey(name: 'address_line2')
  final String? addressLine2;
  
  @JsonKey(name: 'profile_photo_url')
  final String? profilePhoto;
  
  @JsonKey(name: 'referral_code')
  final String? referralCode;
  
  @JsonKey(name: 'referred_by')
  final String? referredBy;
  
  final int? points;
  final String role;
  
  @JsonKey(name: 'email_verified_at')
  final String? emailVerifiedAt;
  
  @JsonKey(name: 'created_at')
  final String? createdAt;
  
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  UserProfileDto({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.addressLine1,
    this.addressLine2,
    this.profilePhoto,
    this.referralCode,
    this.referredBy,
    this.points,
    required this.role,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);
}
