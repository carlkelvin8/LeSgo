// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrdersResponseDto _$OrdersResponseDtoFromJson(Map<String, dynamic> json) =>
    OrdersResponseDto(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => OrderDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] as Map<String, dynamic>?,
      links: json['links'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$OrdersResponseDtoToJson(OrdersResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'meta': instance.meta,
      'links': instance.links,
    };

OrderResponseDto _$OrderResponseDtoFromJson(Map<String, dynamic> json) =>
    OrderResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: OrderDto.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OrderResponseDtoToJson(OrderResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };
