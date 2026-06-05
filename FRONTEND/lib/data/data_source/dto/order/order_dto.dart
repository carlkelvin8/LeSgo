import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/proof_image_utils.dart';
import 'lesbuy_item_dto.dart';

part 'order_dto.g.dart';

// Helper to parse double from either num or string
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String _parseString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

@JsonSerializable()
class DriverUserDto {
  final int id;
  final String name;
  final String? email;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @JsonKey(name: 'profile_picture')
  final String? profilePicture;
  @JsonKey(name: 'profile_photo_url')
  final String? profilePhotoUrl;

  DriverUserDto({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.profilePicture,
    this.profilePhotoUrl,
  });

  factory DriverUserDto.fromJson(Map<String, dynamic> json) =>
      _$DriverUserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DriverUserDtoToJson(this);
}

@JsonSerializable()
class DriverProfileDto {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String status;
  final double? rating;
  @JsonKey(name: 'total_trips')
  final int? totalTrips;
  @JsonKey(name: 'plate_number')
  final String? plateNumber;
  @JsonKey(name: 'vehicle_plate')
  final String? vehiclePlate;
  @JsonKey(name: 'vehicle_type')
  final String? vehicleType;
  final DriverUserDto? user;

  DriverProfileDto({
    required this.id,
    required this.userId,
    required this.status,
    this.rating,
    this.totalTrips,
    this.plateNumber,
    this.vehiclePlate,
    this.vehicleType,
    this.user,
  });

  factory DriverProfileDto.fromJson(Map<String, dynamic> json) =>
      _$DriverProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DriverProfileDtoToJson(this);
}

@JsonSerializable()
class OrderDto {
  final int id;
  @JsonKey(name: 'customer_id')
  final int customerId;
  @JsonKey(name: 'partner_id')
  final int? partnerId;
  @JsonKey(name: 'driver_id')
  final int? driverId;
  @JsonKey(name: 'service_id')
  final int serviceId;
  @JsonKey(name: 'pickup_address_id')
  final int? pickupAddressId;
  @JsonKey(name: 'dropoff_address_id')
  final int? dropoffAddressId;
  @JsonKey(name: 'pickup_address', fromJson: _parseString)
  final String pickupAddress;
  @JsonKey(name: 'pickup_lat', fromJson: _parseDouble)
  final double pickupLat;
  @JsonKey(name: 'pickup_lng', fromJson: _parseDouble)
  final double pickupLng;
  @JsonKey(name: 'pickup_contact_name', fromJson: _parseString)
  final String pickupContactName;
  @JsonKey(name: 'pickup_contact_phone', fromJson: _parseString)
  final String pickupContactPhone;
  @JsonKey(name: 'dropoff_address', fromJson: _parseString)
  final String dropoffAddress;
  @JsonKey(name: 'dropoff_lat', fromJson: _parseDouble)
  final double dropoffLat;
  @JsonKey(name: 'dropoff_lng', fromJson: _parseDouble)
  final double dropoffLng;
  @JsonKey(name: 'dropoff_contact_name', fromJson: _parseString)
  final String dropoffContactName;
  @JsonKey(name: 'dropoff_contact_phone', fromJson: _parseString)
  final String dropoffContactPhone;
  final String? notes;
  @JsonKey(name: 'item_description')
  final String? itemDescription;
  @JsonKey(name: 'estimated_weight_kg', fromJson: _parseDoubleNullable)
  final double? estimatedWeightKg;
  @JsonKey(name: 'vehicle_type')
  final String? vehicleType;
  @JsonKey(name: 'passenger_name')
  final String? passengerName;
  @JsonKey(name: 'voucher_code')
  final String? voucherCode;
  @JsonKey(name: 'discount_amount', fromJson: _parseDouble)
  final double discountAmount;
  @JsonKey(fromJson: _parseString)
  final String status;
  @JsonKey(name: 'scheduled_at')
  final String? scheduledAt;
  @JsonKey(name: 'estimated_distance_m', fromJson: _parseInt)
  final int estimatedDistanceM;
  @JsonKey(name: 'actual_distance_m')
  final int? actualDistanceM;
  @JsonKey(name: 'estimated_fare', fromJson: _parseDouble)
  final double estimatedFare;
  @JsonKey(name: 'actual_fare', fromJson: _parseDoubleNullable)
  final double? actualFare;
  @JsonKey(name: 'total_amount', fromJson: _parseDoubleNullable)
  final double? totalAmount;
  @JsonKey(name: 'delivery_fee', fromJson: _parseDoubleNullable)
  final double? deliveryFee;
  @JsonKey(name: 'service_type')
  final String? serviceType;
  @JsonKey(name: 'fare_breakdown')
  final Map<String, dynamic>? fareBreakdown;
  final Map<String, dynamic>? meta;
  @JsonKey(name: 'payment_method', fromJson: _parseString)
  final String paymentMethod;
  @JsonKey(name: 'payment_status', fromJson: _parseString)
  final String paymentStatus;
  @JsonKey(name: 'cancel_reason')
  final String? cancelReason;
  @JsonKey(name: 'accepted_at')
  final String? acceptedAt;
  @JsonKey(name: 'picked_up_at')
  final String? pickedUpAt;
  @JsonKey(name: 'completed_at')
  final String? completedAt;
  @JsonKey(name: 'cancelled_at')
  final String? cancelledAt;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @JsonKey(name: 'driver_profile')
  final DriverProfileDto? driverProfile;
  @JsonKey(name: 'lesbuy_items')
  final List<LesbuyItemDto>? lesbuyItems;
  @JsonKey(name: 'proof_images', fromJson: ProofImageUtils.parseUrls)
  final List<String> proofImages;

  OrderDto({
    required this.id,
    required this.customerId,
    this.partnerId,
    this.driverId,
    required this.serviceId,
    this.pickupAddressId,
    this.dropoffAddressId,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupContactName,
    required this.pickupContactPhone,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffContactName,
    required this.dropoffContactPhone,
    this.notes,
    this.itemDescription,
    this.estimatedWeightKg,
    this.vehicleType,
    this.passengerName,
    this.voucherCode,
    required this.discountAmount,
    required this.status,
    this.scheduledAt,
    required this.estimatedDistanceM,
    this.actualDistanceM,
    required this.estimatedFare,
    this.actualFare,
    this.totalAmount,
    this.deliveryFee,
    this.serviceType,
    this.fareBreakdown,
    this.meta,
    required this.paymentMethod,
    required this.paymentStatus,
    this.cancelReason,
    this.acceptedAt,
    this.pickedUpAt,
    this.completedAt,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
    this.driverProfile,
    this.lesbuyItems,
    this.proofImages = const [],
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) =>
      _$OrderDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDtoToJson(this);

  // Helper methods for production compatibility
  String get effectiveServiceType {
    if (serviceType != null) return serviceType!;
    
    // Fallback based on service_id
    switch (serviceId) {
      case 1:
        return 'lesgo';
      case 2:
        return 'lesride';
      case 3:
        return 'leseat';
      case 4:
        return 'lesbuy';
      case 5:
        return 'lestransport';
      default:
        return 'unknown';
    }
  }

  double get effectiveTotalAmount {
    if (totalAmount != null && totalAmount! > 0) return totalAmount!;
    
    // Calculate from items if available
    double itemsTotal = 0.0;
    if (lesbuyItems != null && lesbuyItems!.isNotEmpty) {
      for (final item in lesbuyItems!) {
        final price = item.actualPrice ?? item.estimatedPrice ?? 0.0;
        itemsTotal += price * item.quantity;
      }
    }
    
    // Add delivery fee
    final delivery = deliveryFee ?? estimatedFare;
    return itemsTotal + delivery;
  }

  double get effectiveDeliveryFee {
    return deliveryFee ?? estimatedFare;
  }

  List<LesbuyItemDto> get effectiveItems {
    if (lesbuyItems != null && lesbuyItems!.isNotEmpty) {
      return lesbuyItems!;
    }

    if (meta != null && meta!['items'] is List) {
      try {
        final itemsData = meta!['items'] as List;
        return itemsData.map((item) {
          final map = item is Map
              ? Map<String, dynamic>.from(item as Map)
              : <String, dynamic>{'name': item.toString()};
          return LesbuyItemDto(
            id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
            orderId: id,
            name: map['name']?.toString() ?? 'Item',
            quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
            unit: map['unit']?.toString() ?? 'pcs',
            estimatedPrice: _parseDouble(
              map['estimated_price'] ?? map['price'],
            ),
            actualPrice: _parseDouble(
              map['actual_price'] ?? map['price'],
            ),
            imageUrl: map['image_url']?.toString(),
          );
        }).toList();
      } catch (_) {}
    }

    if (meta != null && meta!['order_items'] is List) {
      try {
        final itemsData = meta!['order_items'] as List;
        return itemsData.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return LesbuyItemDto(
            id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
            orderId: id,
            name: map['name']?.toString() ?? 'Item',
            quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
            unit: map['unit']?.toString() ?? 'pcs',
            estimatedPrice: _parseDouble(map['estimated_price'] ?? map['price']),
            actualPrice: _parseDouble(map['actual_price'] ?? map['price']),
            imageUrl: map['image_url']?.toString(),
          );
        }).toList();
      } catch (_) {}
    }

    if (itemDescription != null && itemDescription!.isNotEmpty) {
      return [
        LesbuyItemDto(
          id: 0,
          orderId: id,
          name: itemDescription!,
          quantity: 1,
          unit: 'pcs',
          estimatedPrice: estimatedFare,
          actualPrice: actualFare ?? estimatedFare,
          imageUrl: null,
        ),
      ];
    }

    return [];
  }
}
