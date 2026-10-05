// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvoiceResponseDto _$InvoiceResponseDtoFromJson(Map<String, dynamic> json) =>
    InvoiceResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String?,
      error: json['error'] as String?,
      data: json['data'] == null
          ? null
          : InvoiceDataDto.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$InvoiceResponseDtoToJson(InvoiceResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'error': instance.error,
      'data': instance.data,
    };

InvoiceDataDto _$InvoiceDataDtoFromJson(Map<String, dynamic> json) =>
    InvoiceDataDto(
      invoice: json['invoice'] == null
          ? null
          : InvoiceDto.fromJson(json['invoice'] as Map<String, dynamic>),
      paymentId: (json['payment_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$InvoiceDataDtoToJson(InvoiceDataDto instance) =>
    <String, dynamic>{
      'invoice': instance.invoice,
      'payment_id': instance.paymentId,
    };
