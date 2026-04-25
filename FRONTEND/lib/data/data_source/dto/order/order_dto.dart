import 'package:json_annotation/json_annotation.dart';
import '../user/user_dto.dart';

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

@JsonSerializable()
class DriverProfileDto {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String status;
  final double? rating;
  @JsonKey(name: 'total_trips')
  final int? totalTrips;
  final UserDto? user;

  DriverProfileDto({
    required this.id,
    required this.userId,
    required this.status,
    this.rating,
    this.totalTrips,
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
  @JsonKey(name: 'pickup_address')
  final String pickupAddress;
  @JsonKey(name: 'pickup_lat', fromJson: _parseDouble)
  final double pickupLat;
  @JsonKey(name: 'pickup_lng', fromJson: _parseDouble)
  final double pickupLng;
  @JsonKey(name: 'pickup_contact_name')
  final String pickupContactName;
  @JsonKey(name: 'pickup_contact_phone')
  final String pickupContactPhone;
  @JsonKey(name: 'dropoff_address')
  final String dropoffAddress;
  @JsonKey(name: 'dropoff_lat', fromJson: _parseDouble)
  final double dropoffLat;
  @JsonKey(name: 'dropoff_lng', fromJson: _parseDouble)
  final double dropoffLng;
  @JsonKey(name: 'dropoff_contact_name')
  final String dropoffContactName;
  @JsonKey(name: 'dropoff_contact_phone')
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
  final String status;
  @JsonKey(name: 'scheduled_at')
  final String? scheduledAt;
  @JsonKey(name: 'estimated_distance_m')
  final int estimatedDistanceM;
  @JsonKey(name: 'actual_distance_m')
  final int? actualDistanceM;
  @JsonKey(name: 'estimated_fare', fromJson: _parseDouble)
  final double estimatedFare;
  @JsonKey(name: 'actual_fare', fromJson: _parseDoubleNullable)
  final double? actualFare;
  @JsonKey(name: 'fare_breakdown')
  final Map<String, dynamic>? fareBreakdown;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'payment_status')
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
    this.fareBreakdown,
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
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) =>
      _$OrderDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDtoToJson(this);
}
