// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OtpResponseDto _$OtpResponseDtoFromJson(Map<String, dynamic> json) =>
    OtpResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      verified: json['verified'] as bool?,
      phoneVerificationToken: json['phone_verification_token'] as String?,
      status: json['status'] as String?,
      channel: json['channel'] as String?,
      verificationSid: json['verificationSid'] as String?,
      otp: json['otp'] as String?,
      fallback: json['fallback'] as bool?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$OtpResponseDtoToJson(OtpResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'verified': instance.verified,
      'phone_verification_token': instance.phoneVerificationToken,
      'status': instance.status,
      'channel': instance.channel,
      'verificationSid': instance.verificationSid,
      'otp': instance.otp,
      'fallback': instance.fallback,
      'error': instance.error,
    };
