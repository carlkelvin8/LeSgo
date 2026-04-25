// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_address_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteAddressResponseDto _$DeleteAddressResponseDtoFromJson(
  Map<String, dynamic> json,
) => DeleteAddressResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$DeleteAddressResponseDtoToJson(
  DeleteAddressResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'error': instance.error,
};
