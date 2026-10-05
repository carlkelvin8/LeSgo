// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partners_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PartnersResponseDto _$PartnersResponseDtoFromJson(Map<String, dynamic> json) =>
    PartnersResponseDto(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => PartnerDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaDto.fromJson(json['meta'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$PartnersResponseDtoToJson(
  PartnersResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'meta': instance.meta,
  'error': instance.error,
};
