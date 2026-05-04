import 'package:json_annotation/json_annotation.dart';

part 'order_dto.g.dart';

@JsonSerializable()
class OrderDto {
  final int id;
  @JsonKey(name: 'reference_number')
  final String referenceNumber;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'driver_id')
  final int? driverId;
  @JsonKey(name: 'partner_id')
  final int? partnerId;
  @JsonKey(name: 'service_id')
  final int serviceId;
  final String status;
  @JsonKey(name: 'pickup_address')
  final String pickupAddress;
  @JsonKey(name: 'pickup_lat')
  final double? pickupLat;
  @JsonKey(name: 'pickup_lng')
  final double? pickupLng;
  @JsonKey(name: 'dropoff_address')
  final String dropoffAddress;
  @JsonKey(name: 'dropoff_lat')
  final double? dropoffLat;
  @JsonKey(name: 'dropoff_lng')
  final double? dropoffLng;
  @JsonKey(name: 'distance_km')
  final double? distanceKm;
  @JsonKey(name: 'estimated_duration_minutes')
  final int? estimatedDurationMinutes;
  @JsonKey(name: 'base_fare')
  final double baseFare;
  @JsonKey(name: 'distance_fare')
  final double distanceFare;
  @JsonKey(name: 'service_fee')
  final double serviceFee;
  @JsonKey(name: 'total_fare')
  final double totalFare;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'payment_status')
  final String paymentStatus;
  @JsonKey(name: 'special_instructions')
  final String? specialInstructions;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  
  // Relationships
  final UserDto? user;
  final DriverDto? driver;
  final OrderPartnerDto? partner;
  final ServiceDto? service;
  @JsonKey(name: 'order_items')
  final List<OrderItemDto>? orderItems;
  
  OrderDto({
    required this.id,
    required this.referenceNumber,
    required this.userId,
    this.driverId,
    this.partnerId,
    required this.serviceId,
    required this.status,
    required this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    required this.dropoffAddress,
    this.dropoffLat,
    this.dropoffLng,
    this.distanceKm,
    this.estimatedDurationMinutes,
    required this.baseFare,
    required this.distanceFare,
    required this.serviceFee,
    required this.totalFare,
    required this.paymentMethod,
    required this.paymentStatus,
    this.specialInstructions,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.driver,
    this.partner,
    this.service,
    this.orderItems,
  });
  
  factory OrderDto.fromJson(Map<String, dynamic> json) => 
      _$OrderDtoFromJson(json);
  Map<String, dynamic> toJson() => _$OrderDtoToJson(this);
}

@JsonSerializable()
class OrderItemDto {
  final int id;
  @JsonKey(name: 'order_id')
  final int orderId;
  @JsonKey(name: 'menu_item_id')
  final int? menuItemId;
  @JsonKey(name: 'item_name')
  final String itemName;
  @JsonKey(name: 'item_description')
  final String? itemDescription;
  final int quantity;
  @JsonKey(name: 'unit_price')
  final double unitPrice;
  @JsonKey(name: 'total_price')
  final double totalPrice;
  final String? options;
  
  OrderItemDto({
    required this.id,
    required this.orderId,
    this.menuItemId,
    required this.itemName,
    this.itemDescription,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.options,
  });
  
  factory OrderItemDto.fromJson(Map<String, dynamic> json) => 
      _$OrderItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemDtoToJson(this);
}

@JsonSerializable()
class UserDto {
  final int id;
  final String name;
  final String email;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  
  UserDto({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
  });
  
  factory UserDto.fromJson(Map<String, dynamic> json) => 
      _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}

@JsonSerializable()
class DriverDto {
  final int id;
  final String name;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  
  DriverDto({
    required this.id,
    required this.name,
    this.phoneNumber,
  });
  
  factory DriverDto.fromJson(Map<String, dynamic> json) => 
      _$DriverDtoFromJson(json);
  Map<String, dynamic> toJson() => _$DriverDtoToJson(this);
}

@JsonSerializable()
class OrderPartnerDto {
  final int id;
  final String name;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  
  OrderPartnerDto({
    required this.id,
    required this.name,
    this.logoUrl,
  });
  
  factory OrderPartnerDto.fromJson(Map<String, dynamic> json) => 
      _$OrderPartnerDtoFromJson(json);
  Map<String, dynamic> toJson() => _$OrderPartnerDtoToJson(this);
}

@JsonSerializable()
class ServiceDto {
  final int id;
  final String name;
  final String? slug;
  
  ServiceDto({
    required this.id,
    required this.name,
    this.slug,
  });
  
  factory ServiceDto.fromJson(Map<String, dynamic> json) => 
      _$ServiceDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceDtoToJson(this);
}
