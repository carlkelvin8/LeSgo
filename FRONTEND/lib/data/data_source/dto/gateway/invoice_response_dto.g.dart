// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvoiceResponseDto _$InvoiceResponseDtoFromJson(Map<String, dynamic> json) =>
    InvoiceResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: InvoiceDto.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$InvoiceResponseDtoToJson(InvoiceResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };
