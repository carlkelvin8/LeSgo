// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_vouchers_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvailableVouchersResponseDto _$AvailableVouchersResponseDtoFromJson(
  Map<String, dynamic> json,
) => AvailableVouchersResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: (json['data'] as List<dynamic>)
      .map((e) => VoucherDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AvailableVouchersResponseDtoToJson(
  AvailableVouchersResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};
