import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/menu_item_options.dart';

part 'order_dto.g.dart';

Map<String, dynamic>? _parseSelectedOptions(dynamic value) {
  if (value == null || (value is List && value.isEmpty)) return null;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Invalid order item selected options');
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? _parseOrderItemImageUrl(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is Map) {
    final url = value['url'] ?? value['image_url'];
    return url?.toString();
  }
  return null;
}

double? _parseFareBreakdownSubtotal(dynamic value) {
  if (value is! Map) return null;
  return _parseDouble(value['subtotal']) ??
      _parseDouble(value['order_value']) ??
      _parseDouble(value['items_total']);
}

double? _parseMetaOrderValue(dynamic value) {
  if (value is! Map) return null;
  return _parseDouble(value['order_value']) ??
      _parseDouble(value['subtotal']) ??
      _parseDouble(value['grand_total']);
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
  @JsonKey(name: 'completed_at')
  final String? completedAt;
  @JsonKey(name: 'partner_share', fromJson: _parseDouble)
  final double? partnerShare;
  @JsonKey(name: 'fare_breakdown', fromJson: _parseFareBreakdownSubtotal)
  final double? fareBreakdownSubtotal;
  @JsonKey(name: 'meta', fromJson: _parseMetaOrderValue)
  final double? metaOrderValue;
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
    this.completedAt,
    this.partnerShare,
    this.fareBreakdownSubtotal,
    this.metaOrderValue,
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
  @JsonKey(name: 'notes')
  final String? notes;
  @JsonKey(name: 'selected_options', fromJson: _parseSelectedOptions)
  final Map<String, dynamic>? selectedOptionsRaw;
  @JsonKey(name: 'image_url', fromJson: _parseOrderItemImageUrl)
  final String? imageUrl;

  SelectedMenuOptions get selectedOptions =>
      SelectedMenuOptions.fromApiMap(selectedOptionsRaw);

  String? get optionsDisplay {
    if (notes != null && notes!.trim().isNotEmpty) return notes;
    if (!selectedOptions.isEmpty) return selectedOptions.formatDisplay();
    return null;
  }
  
  OrderItemDto({
    required this.id,
    required this.orderId,
    this.menuItemId,
    required this.itemName,
    this.itemDescription,
    required this.quantity,
    this.unitPrice,
    this.totalPrice,
    this.notes,
    this.selectedOptionsRaw,
    this.imageUrl,
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
  @JsonKey(name: 'profile_photo_url')
  final String? profilePhotoUrl;
  @JsonKey(name: 'profile_picture')
  final String? profilePicture;
  
  UserDto({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profilePhotoUrl,
    this.profilePicture,
  });

  String? get resolvedProfilePhotoUrl {
    final photo = profilePhotoUrl ?? profilePicture;
    if (photo == null || photo.trim().isEmpty) return null;
    return photo;
  }
  
  factory UserDto.fromJson(Map<String, dynamic> json) => 
      _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}

class DriverDto {
  final int id;
  final String name;
  final String? phoneNumber;
  final String? vehicleType;
  final String? plateNumber;
  final String? profilePictureUrl;

  DriverDto({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.vehicleType,
    this.plateNumber,
    this.profilePictureUrl,
  });

  factory DriverDto.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : null;

    final plate = json['plate_number']?.toString().trim();
    final legacyPlate = json['vehicle_plate']?.toString().trim();
    final resolvedPlate = (plate != null && plate.isNotEmpty)
        ? plate
        : (legacyPlate != null && legacyPlate.isNotEmpty ? legacyPlate : null);

    final photo = user?['profile_photo_url'] ??
        user?['profile_picture'] ??
        json['profile_photo_url'] ??
        json['profile_picture'];

    return DriverDto(
      id: (json['id'] as num).toInt(),
      name: user?['name']?.toString() ??
          json['name']?.toString() ??
          'Driver',
      phoneNumber: user?['phone_number']?.toString() ??
          json['phone_number']?.toString(),
      vehicleType: json['vehicle_type']?.toString(),
      plateNumber: resolvedPlate,
      profilePictureUrl: photo?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone_number': phoneNumber,
    'vehicle_type': vehicleType,
    'plate_number': plateNumber,
    'profile_picture_url': profilePictureUrl,
  };
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
