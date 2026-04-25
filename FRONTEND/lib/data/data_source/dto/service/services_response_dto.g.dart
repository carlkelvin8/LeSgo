// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServicesResponseDto _$ServicesResponseDtoFromJson(Map<String, dynamic> json) =>
    ServicesResponseDto(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => ServiceDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaDto.fromJson(json['meta'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$ServicesResponseDtoToJson(
  ServicesResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'meta': instance.meta,
  'error': instance.error,
};

MetaDto _$MetaDtoFromJson(Map<String, dynamic> json) => MetaDto(
  currentPage: (json['current_page'] as num).toInt(),
  lastPage: (json['last_page'] as num).toInt(),
  perPage: (json['per_page'] as num).toInt(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$MetaDtoToJson(MetaDto instance) => <String, dynamic>{
  'current_page': instance.currentPage,
  'last_page': instance.lastPage,
  'per_page': instance.perPage,
  'total': instance.total,
};
