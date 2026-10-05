// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesbuy_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LesbuyItemDto _$LesbuyItemDtoFromJson(Map<String, dynamic> json) =>
    LesbuyItemDto(
      id: (json['id'] as num).toInt(),
      orderId: (json['order_id'] as num).toInt(),
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unit: json['unit'] as String?,
      notes: json['notes'] as String?,
      imageUrl: json['image_url'] as String?,
      estimatedPrice: _parseDoubleNullable(json['estimated_price']),
      actualPrice: _parseDoubleNullable(json['actual_price']),
    );

Map<String, dynamic> _$LesbuyItemDtoToJson(LesbuyItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'name': instance.name,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'notes': instance.notes,
      'image_url': instance.imageUrl,
      'estimated_price': instance.estimatedPrice,
      'actual_price': instance.actualPrice,
    };
