import 'package:json_annotation/json_annotation.dart';

part 'create_order_request_dto.g.dart';

@JsonSerializable()
class CreateOrderRequestDto {
  @JsonKey(name: 'service_id')
  final int serviceId;
  @JsonKey(name: 'estimated_distance_m')
  final int estimatedDistanceM;
  final OrderAddressDto pickup;
  final OrderAddressDto dropoff;
  final String? notes;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'items')
  final List<OrderItemDto>? items;
  @JsonKey(name: 'meta')
  final Map<String, dynamic>? meta;

  CreateOrderRequestDto({
    required this.serviceId,
    required this.estimatedDistanceM,
    required this.pickup,
    required this.dropoff,
    this.notes,
    required this.paymentMethod,
    this.items,
    this.meta,
  });

  factory CreateOrderRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateOrderRequestDtoToJson(this);
}

@JsonSerializable()
class OrderAddressDto {
  final String address;
  final double lat;
  final double lng;
  @JsonKey(name: 'contact_name')
  final String? contactName;
  @JsonKey(name: 'contact_phone')
  final String? contactPhone;

  OrderAddressDto({
    required this.address,
    required this.lat,
    required this.lng,
    this.contactName,
    this.contactPhone,
  });

  factory OrderAddressDto.fromJson(Map<String, dynamic> json) =>
      _$OrderAddressDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderAddressDtoToJson(this);
}

@JsonSerializable()
class OrderItemDto {
  final String name;
  final int quantity;
  @JsonKey(name: 'estimated_price')
  final double? estimatedPrice;
  final String? notes;

  OrderItemDto({
    required this.name,
    required this.quantity,
    this.estimatedPrice,
    this.notes,
  });

  factory OrderItemDto.fromJson(Map<String, dynamic> json) =>
      _$OrderItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemDtoToJson(this);
}
