import 'package:json_annotation/json_annotation.dart';

part 'otp_response_dto.g.dart';

@JsonSerializable()
class OtpResponseDto {
  final bool success;
  final String message;
  final bool? verified;
  final String? status;
  final String? channel;
  @JsonKey(name: 'verification_sid')
  final String? verificationSid;
  final String? otp;
  final bool? fallback;
  final String? error;

  const OtpResponseDto({
    required this.success,
    required this.message,
    this.verified,
    this.status,
    this.channel,
    this.verificationSid,
    this.otp,
    this.fallback,
    this.error,
  });

  factory OtpResponseDto.fromJson(Map<String, dynamic> json) =>
      _$OtpResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OtpResponseDtoToJson(this);
}
