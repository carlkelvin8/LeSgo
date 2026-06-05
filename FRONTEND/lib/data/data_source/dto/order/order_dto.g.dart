// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverUserDto _$DriverUserDtoFromJson(Map<String, dynamic> json) =>
    DriverUserDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? 'Driver',
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      profilePicture: json['profile_picture'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );

Map<String, dynamic> _$DriverUserDtoToJson(DriverUserDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone_number': instance.phoneNumber,
      'profile_picture': instance.profilePicture,
      'profile_photo_url': instance.profilePhotoUrl,
    };

DriverProfileDto _$DriverProfileDtoFromJson(Map<String, dynamic> json) =>
    DriverProfileDto(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      status: json['status'] as String,
      rating: (json['rating'] as num?)?.toDouble(),
      totalTrips: (json['total_trips'] as num?)?.toInt(),
      plateNumber: json['plate_number'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      user: json['user'] == null
          ? null
          : DriverUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DriverProfileDtoToJson(DriverProfileDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'status': instance.status,
      'rating': instance.rating,
      'total_trips': instance.totalTrips,
      'plate_number': instance.plateNumber,
      'vehicle_plate': instance.vehiclePlate,
      'vehicle_type': instance.vehicleType,
      'user': instance.user?.toJson(),
    };

OrderDto _$OrderDtoFromJson(Map<String, dynamic> json) => OrderDto(
  id: (json['id'] as num).toInt(),
  customerId: (json['customer_id'] as num).toInt(),
  partnerId: (json['partner_id'] as num?)?.toInt(),
  driverId: (json['driver_id'] as num?)?.toInt(),
  serviceId: (json['service_id'] as num).toInt(),
  pickupAddressId: (json['pickup_address_id'] as num?)?.toInt(),
  dropoffAddressId: (json['dropoff_address_id'] as num?)?.toInt(),
  pickupAddress: _parseString(json['pickup_address']),
  pickupLat: _parseDouble(json['pickup_lat']),
  pickupLng: _parseDouble(json['pickup_lng']),
  pickupContactName: _parseString(json['pickup_contact_name']),
  pickupContactPhone: _parseString(json['pickup_contact_phone']),
  dropoffAddress: _parseString(json['dropoff_address']),
  dropoffLat: _parseDouble(json['dropoff_lat']),
  dropoffLng: _parseDouble(json['dropoff_lng']),
  dropoffContactName: _parseString(json['dropoff_contact_name']),
  dropoffContactPhone: _parseString(json['dropoff_contact_phone']),
  notes: json['notes'] as String?,
  itemDescription: json['item_description'] as String?,
  estimatedWeightKg: _parseDoubleNullable(json['estimated_weight_kg']),
  vehicleType: json['vehicle_type'] as String?,
  passengerName: json['passenger_name'] as String?,
  voucherCode: json['voucher_code'] as String?,
  discountAmount: _parseDouble(json['discount_amount']),
  status: _parseString(json['status']),
  scheduledAt: json['scheduled_at'] as String?,
  estimatedDistanceM: _parseInt(json['estimated_distance_m']),
  actualDistanceM: (json['actual_distance_m'] as num?)?.toInt(),
  estimatedFare: _parseDouble(json['estimated_fare']),
  actualFare: _parseDoubleNullable(json['actual_fare']),
  totalAmount: _parseDoubleNullable(json['total_amount']),
  deliveryFee: _parseDoubleNullable(json['delivery_fee']),
  serviceType: json['service_type'] as String?,
  fareBreakdown: json['fare_breakdown'] as Map<String, dynamic>?,
  meta: json['meta'] as Map<String, dynamic>?,
  paymentMethod: _parseString(json['payment_method']),
  paymentStatus: _parseString(json['payment_status']),
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
  lesbuyItems: (json['lesbuy_items'] as List<dynamic>?)
      ?.map((e) => LesbuyItemDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  proofImages: ProofImageUtils.fromOrderMap(json),
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
  'total_amount': instance.totalAmount,
  'delivery_fee': instance.deliveryFee,
  'service_type': instance.serviceType,
  'fare_breakdown': instance.fareBreakdown,
  'meta': instance.meta,
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
  'lesbuy_items': instance.lesbuyItems,
  'proof_images': instance.proofImages,
};
