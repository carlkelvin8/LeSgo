// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverProfileDto _$DriverProfileDtoFromJson(Map<String, dynamic> json) =>
    DriverProfileDto(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      status: json['status'] as String,
      rating: (json['rating'] as num?)?.toDouble(),
      totalTrips: (json['total_trips'] as num?)?.toInt(),
      user: json['user'] == null
          ? null
          : UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DriverProfileDtoToJson(DriverProfileDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'status': instance.status,
      'rating': instance.rating,
      'total_trips': instance.totalTrips,
      'user': instance.user,
    };

OrderDto _$OrderDtoFromJson(Map<String, dynamic> json) => OrderDto(
  id: (json['id'] as num).toInt(),
  customerId: (json['customer_id'] as num).toInt(),
  partnerId: (json['partner_id'] as num?)?.toInt(),
  driverId: (json['driver_id'] as num?)?.toInt(),
  serviceId: (json['service_id'] as num).toInt(),
  pickupAddressId: (json['pickup_address_id'] as num?)?.toInt(),
  dropoffAddressId: (json['dropoff_address_id'] as num?)?.toInt(),
  pickupAddress: json['pickup_address'] as String,
  pickupLat: _parseDouble(json['pickup_lat']),
  pickupLng: _parseDouble(json['pickup_lng']),
  pickupContactName: json['pickup_contact_name'] as String,
  pickupContactPhone: json['pickup_contact_phone'] as String,
  dropoffAddress: json['dropoff_address'] as String,
  dropoffLat: _parseDouble(json['dropoff_lat']),
  dropoffLng: _parseDouble(json['dropoff_lng']),
  dropoffContactName: json['dropoff_contact_name'] as String,
  dropoffContactPhone: json['dropoff_contact_phone'] as String,
  notes: json['notes'] as String?,
  itemDescription: json['item_description'] as String?,
  estimatedWeightKg: _parseDoubleNullable(json['estimated_weight_kg']),
  vehicleType: json['vehicle_type'] as String?,
  passengerName: json['passenger_name'] as String?,
  voucherCode: json['voucher_code'] as String?,
  discountAmount: _parseDouble(json['discount_amount']),
  status: json['status'] as String,
  scheduledAt: json['scheduled_at'] as String?,
  estimatedDistanceM: (json['estimated_distance_m'] as num).toInt(),
  actualDistanceM: (json['actual_distance_m'] as num?)?.toInt(),
  estimatedFare: _parseDouble(json['estimated_fare']),
  actualFare: _parseDoubleNullable(json['actual_fare']),
  fareBreakdown: json['fare_breakdown'] as Map<String, dynamic>?,
  paymentMethod: json['payment_method'] as String,
  paymentStatus: json['payment_status'] as String,
  cancelReason: json['cancel_reason'] as String?,
  acceptedAt: json['accepted_at'] as String?,
  pickedUpAt: json['picked_up_at'] as String?,
  completedAt: json['completed_at'] as String?,
  cancelledAt: json['cancelled_at'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  driverProfile: json['driver_profile'] == null
      ? null
      : DriverProfileDto.fromJson(
          json['driver_profile'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$OrderDtoToJson(OrderDto instance) => <String, dynamic>{
  'id': instance.id,
  'customer_id': instance.customerId,
  'partner_id': instance.partnerId,
  'driver_id': instance.driverId,
  'service_id': instance.serviceId,
  'pickup_address_id': instance.pickupAddressId,
  'dropoff_address_id': instance.dropoffAddressId,
  'pickup_address': instance.pickupAddress,
  'pickup_lat': instance.pickupLat,
  'pickup_lng': instance.pickupLng,
  'pickup_contact_name': instance.pickupContactName,
  'pickup_contact_phone': instance.pickupContactPhone,
  'dropoff_address': instance.dropoffAddress,
  'dropoff_lat': instance.dropoffLat,
  'dropoff_lng': instance.dropoffLng,
  'dropoff_contact_name': instance.dropoffContactName,
  'dropoff_contact_phone': instance.dropoffContactPhone,
  'notes': instance.notes,
  'item_description': instance.itemDescription,
  'estimated_weight_kg': instance.estimatedWeightKg,
  'vehicle_type': instance.vehicleType,
  'passenger_name': instance.passengerName,
  'voucher_code': instance.voucherCode,
  'discount_amount': instance.discountAmount,
  'status': instance.status,
  'scheduled_at': instance.scheduledAt,
  'estimated_distance_m': instance.estimatedDistanceM,
  'actual_distance_m': instance.actualDistanceM,
  'estimated_fare': instance.estimatedFare,
  'actual_fare': instance.actualFare,
  'fare_breakdown': instance.fareBreakdown,
  'payment_method': instance.paymentMethod,
  'payment_status': instance.paymentStatus,
  'cancel_reason': instance.cancelReason,
  'accepted_at': instance.acceptedAt,
  'picked_up_at': instance.pickedUpAt,
  'completed_at': instance.completedAt,
  'cancelled_at': instance.cancelledAt,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'driver_profile': instance.driverProfile,
};
