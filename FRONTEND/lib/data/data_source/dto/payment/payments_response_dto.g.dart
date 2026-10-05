// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentMetaDto _$PaymentMetaDtoFromJson(Map<String, dynamic> json) =>
    PaymentMetaDto(
      currentPage: (json['current_page'] as num).toInt(),
      lastPage: (json['last_page'] as num).toInt(),
      perPage: (json['per_page'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$PaymentMetaDtoToJson(PaymentMetaDto instance) =>
    <String, dynamic>{
      'current_page': instance.currentPage,
      'last_page': instance.lastPage,
      'per_page': instance.perPage,
      'total': instance.total,
    };

PaymentLinksDto _$PaymentLinksDtoFromJson(Map<String, dynamic> json) =>
    PaymentLinksDto(
      first: json['first'] as String?,
      last: json['last'] as String?,
      prev: json['prev'] as String?,
      next: json['next'] as String?,
    );

Map<String, dynamic> _$PaymentLinksDtoToJson(PaymentLinksDto instance) =>
    <String, dynamic>{
      'first': instance.first,
      'last': instance.last,
      'prev': instance.prev,
      'next': instance.next,
    };

PaymentsResponseDto _$PaymentsResponseDtoFromJson(Map<String, dynamic> json) =>
    PaymentsResponseDto(
      success: json['success'] as bool,
      error: json['error'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => PaymentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] == null
          ? null
          : PaymentMetaDto.fromJson(json['meta'] as Map<String, dynamic>),
      links: json['links'] == null
          ? null
          : PaymentLinksDto.fromJson(json['links'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PaymentsResponseDtoToJson(
  PaymentsResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'error': instance.error,
  'data': instance.data,
  'meta': instance.meta,
  'links': instance.links,
};
