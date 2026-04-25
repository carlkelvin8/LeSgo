// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentResponseDto _$PaymentResponseDtoFromJson(Map<String, dynamic> json) =>
    PaymentResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String?,
      error: json['error'] as String?,
      data: json['data'] == null
          ? null
          : PaymentDto.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PaymentResponseDtoToJson(PaymentResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'error': instance.error,
      'data': instance.data,
    };
