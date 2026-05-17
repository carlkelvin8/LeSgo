// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_order_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateOrderRequestDto _$CreateOrderRequestDtoFromJson(
  Map<String, dynamic> json,
) => CreateOrderRequestDto(
  serviceId: (json['service_id'] as num).toInt(),
  partnerId: (json['partner_id'] as num?)?.toInt(),
  estimatedDistanceM: (json['estimated_distance_m'] as num).toInt(),
  pickup: OrderAddressDto.fromJson(json['pickup'] as Map<String, dynamic>),
  dropoff: OrderAddressDto.fromJson(json['dropoff'] as Map<String, dynamic>),
  notes: json['notes'] as String?,
  paymentMethod: json['payment_method'] as String? ?? 'cash',
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => OrderItemDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] as Map<String, dynamic>?,
  voucherCode: json['voucher_code'] as String?,
  discountAmount: (json['discount_amount'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CreateOrderRequestDtoToJson(
  CreateOrderRequestDto instance,
) => <String, dynamic>{
  'service_id': instance.serviceId,
  'partner_id': instance.partnerId,
  'estimated_distance_m': instance.estimatedDistanceM,
  'pickup': instance.pickup,
  'dropoff': instance.dropoff,
  'notes': instance.notes,
  'payment_method': instance.paymentMethod,
  'items': instance.items,
  'meta': instance.meta,
  'voucher_code': instance.voucherCode,
  'discount_amount': instance.discountAmount,
};

OrderAddressDto _$OrderAddressDtoFromJson(Map<String, dynamic> json) =>
    OrderAddressDto(
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      contactName: json['contact_name'] as String?,
      contactPhone: json['contact_phone'] as String?,
    );

Map<String, dynamic> _$OrderAddressDtoToJson(OrderAddressDto instance) =>
    <String, dynamic>{
      'address': instance.address,
      'lat': instance.lat,
      'lng': instance.lng,
      'contact_name': instance.contactName,
      'contact_phone': instance.contactPhone,
    };

OrderItemDto _$OrderItemDtoFromJson(Map<String, dynamic> json) => OrderItemDto(
  name: json['name'] as String,
  quantity: (json['quantity'] as num).toInt(),
  estimatedPrice: (json['estimated_price'] as num?)?.toDouble(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$OrderItemDtoToJson(OrderItemDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'quantity': instance.quantity,
      'estimated_price': instance.estimatedPrice,
      'notes': instance.notes,
    };
