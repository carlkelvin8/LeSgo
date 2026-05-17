import 'package:json_annotation/json_annotation.dart';

part 'order_dto.g.dart';

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

@JsonSerializable()
class OrderDto {
  final int id;
  @JsonKey(name: 'reference_number')
  final String? referenceNumber;
  @JsonKey(name: 'customer_id')
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
  @JsonKey(name: 'pickup_lat', fromJson: _parseDouble)
  final double? pickupLat;
  @JsonKey(name: 'pickup_lng', fromJson: _parseDouble)
  final double? pickupLng;
  @JsonKey(name: 'dropoff_address')
  final String dropoffAddress;
  @JsonKey(name: 'dropoff_lat', fromJson: _parseDouble)
  final double? dropoffLat;
  @JsonKey(name: 'dropoff_lng', fromJson: _parseDouble)
  final double? dropoffLng;
  @JsonKey(name: 'estimated_distance_m')
  final int? distanceKm;
  @JsonKey(name: 'estimated_duration_minutes')
  final int? estimatedDurationMinutes;
  @JsonKey(name: 'base_fare', fromJson: _parseDouble)
  final double? baseFare;
  @JsonKey(name: 'distance_fare', fromJson: _parseDouble)
  final double? distanceFare;
  @JsonKey(name: 'service_fee', fromJson: _parseDouble)
  final double? serviceFee;
  @JsonKey(name: 'total_fare', fromJson: _parseDouble)
  final double? totalFare;
  @JsonKey(name: 'estimated_fare', fromJson: _parseDouble)
  final double? estimatedFare;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'payment_status')
  final String paymentStatus;
  @JsonKey(name: 'notes')
  final String? specialInstructions;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  
  // Relationships
  @JsonKey(name: 'customer')
  final UserDto? user;
  @JsonKey(name: 'driver_profile')
  final DriverDto? driver;
  final OrderPartnerDto? partner;
  final ServiceDto? service;
  @JsonKey(name: 'lesbuy_items')
  final List<OrderItemDto>? orderItems;
  
  OrderDto({
    required this.id,
    this.referenceNumber,
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
    this.baseFare,
    this.distanceFare,
    this.serviceFee,
    this.totalFare,
    this.estimatedFare,
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
  @JsonKey(name: 'name')
  final String itemName;
  @JsonKey(name: 'item_description')
  final String? itemDescription;
  final int quantity;
  @JsonKey(name: 'estimated_price', fromJson: _parseDouble)
  final double? unitPrice;
  @JsonKey(name: 'actual_price', fromJson: _parseDouble)
  final double? totalPrice;
  final String? options;
  
  OrderItemDto({
    required this.id,
    required this.orderId,
    this.menuItemId,
    required this.itemName,
    this.itemDescription,
    required this.quantity,
    this.unitPrice,
    this.totalPrice,
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
