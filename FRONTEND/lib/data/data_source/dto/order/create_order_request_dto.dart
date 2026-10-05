import 'package:json_annotation/json_annotation.dart';

part 'create_order_request_dto.g.dart';

@JsonSerializable()
class CreateOrderRequestDto {
  @JsonKey(name: 'service_id')
  final int serviceId;
  @JsonKey(name: 'partner_id')
  final int? partnerId;
  @JsonKey(name: 'estimated_distance_m')
  final int estimatedDistanceM;
  final OrderAddressDto pickup;
  final OrderAddressDto dropoff;
  final String? notes;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'vehicle_type')
  final String? vehicleType;
  @JsonKey(name: 'passenger_name')
  final String? passengerName;
  @JsonKey(name: 'items')
  final List<OrderItemDto>? items;
  @JsonKey(name: 'meta')
  final Map<String, dynamic>? meta;
  @JsonKey(name: 'voucher_code')
  final String? voucherCode;
  @JsonKey(name: 'discount_amount')
  final double? discountAmount;
  @JsonKey(name: 'scheduled_delivery_time')
  final String? scheduledDeliveryTime;

  CreateOrderRequestDto({
    required this.serviceId,
    this.partnerId,
    required this.estimatedDistanceM,
    required this.pickup,
    required this.dropoff,
    this.notes,
    this.paymentMethod = 'cash',
    this.vehicleType,
    this.passengerName,
    this.items,
    this.meta,
    this.voucherCode,
    this.discountAmount,
    this.scheduledDeliveryTime,
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
  final String? source;
  final String name;
  final int quantity;
  @JsonKey(name: 'estimated_price')
  final double? estimatedPrice;
  final String? notes;
  @JsonKey(name: 'menu_item_id')
  final int? menuItemId;
  @JsonKey(name: 'selected_options')
  final Map<String, dynamic>? selectedOptions;

  OrderItemDto({
    this.source,
    required this.name,
    required this.quantity,
    this.estimatedPrice,
    this.notes,
    this.menuItemId,
    this.selectedOptions,
  });

  factory OrderItemDto.fromJson(Map<String, dynamic> json) =>
      _$OrderItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemDtoToJson(this);
}
