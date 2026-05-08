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
      status: json['status'] as String?,
      channel: json['channel'] as String?,
      verificationSid: json['verification_sid'] as String?,
      otp: json['otp'] as String?,
      fallback: json['fallback'] as bool?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$OtpResponseDtoToJson(OtpResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'verified': instance.verified,
      'status': instance.status,
      'channel': instance.channel,
      'verification_sid': instance.verificationSid,
      'otp': instance.otp,
      'fallback': instance.fallback,
      'error': instance.error,
    };
