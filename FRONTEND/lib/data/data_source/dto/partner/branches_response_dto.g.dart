// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branches_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BranchesResponseDto _$BranchesResponseDtoFromJson(Map<String, dynamic> json) =>
    BranchesResponseDto(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => BranchDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaDto.fromJson(json['meta'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$BranchesResponseDtoToJson(
  BranchesResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'meta': instance.meta,
  'error': instance.error,
};
