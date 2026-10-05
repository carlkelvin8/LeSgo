// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BranchResponseDto _$BranchResponseDtoFromJson(Map<String, dynamic> json) =>
    BranchResponseDto(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : BranchDto.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$BranchResponseDtoToJson(BranchResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'message': instance.message,
      'error': instance.error,
    };
