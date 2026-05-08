// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderDto _$OrderDtoFromJson(Map<String, dynamic> json) => OrderDto(
      id: (json['id'] as num).toInt(),
      referenceNumber: json['reference_number'] as String,
      userId: (json['user_id'] as num).toInt(),
      driverId: (json['driver_id'] as num?)?.toInt(),
      partnerId: (json['partner_id'] as num?)?.toInt(),
      serviceId: (json['service_id'] as num).toInt(),
      status: json['status'] as String,
      pickupAddress: json['pickup_address'] as String,
      pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
      pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
      dropoffAddress: json['dropoff_address'] as String,
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble(),
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      estimatedDurationMinutes:
          (json['estimated_duration_minutes'] as num?)?.toInt(),
      baseFare: (json['base_fare'] as num).toDouble(),
      distanceFare: (json['distance_fare'] as num).toDouble(),
      serviceFee: (json['service_fee'] as num).toDouble(),
      totalFare: (json['total_fare'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String,
      specialInstructions: json['special_instructions'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      user: json['user'] == null
          ? null
          : UserDto.fromJson(json['user'] as Map<String, dynamic>),
      driver: json['driver'] == null
          ? null
          : DriverDto.fromJson(json['driver'] as Map<String, dynamic>),
      partner: json['partner'] == null
          ? null
          : OrderPartnerDto.fromJson(json['partner'] as Map<String, dynamic>),
      service: json['service'] == null
          ? null
          : ServiceDto.fromJson(json['service'] as Map<String, dynamic>),
      orderItems: (json['order_items'] as List<dynamic>?)
          ?.map((e) => OrderItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OrderDtoToJson(OrderDto instance) => <String, dynamic>{
      'id': instance.id,
      'reference_number': instance.referenceNumber,
      'user_id': instance.userId,
      'driver_id': instance.driverId,
      'partner_id': instance.partnerId,
      'service_id': instance.serviceId,
      'status': instance.status,
      'pickup_address': instance.pickupAddress,
      'pickup_lat': instance.pickupLat,
      'pickup_lng': instance.pickupLng,
      'dropoff_address': instance.dropoffAddress,
      'dropoff_lat': instance.dropoffLat,
      'dropoff_lng': instance.dropoffLng,
      'distance_km': instance.distanceKm,
      'estimated_duration_minutes': instance.estimatedDurationMinutes,
      'base_fare': instance.baseFare,
      'distance_fare': instance.distanceFare,
      'service_fee': instance.serviceFee,
      'total_fare': instance.totalFare,
      'payment_method': instance.paymentMethod,
      'payment_status': instance.paymentStatus,
      'special_instructions': instance.specialInstructions,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'user': instance.user,
      'driver': instance.driver,
      'partner': instance.partner,
      'service': instance.service,
      'order_items': instance.orderItems,
    };

OrderItemDto _$OrderItemDtoFromJson(Map<String, dynamic> json) => OrderItemDto(
      id: (json['id'] as num).toInt(),
      orderId: (json['order_id'] as num).toInt(),
      menuItemId: (json['menu_item_id'] as num?)?.toInt(),
      itemName: json['item_name'] as String,
      itemDescription: json['item_description'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      options: json['options'] as String?,
    );

Map<String, dynamic> _$OrderItemDtoToJson(OrderItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'menu_item_id': instance.menuItemId,
      'item_name': instance.itemName,
      'item_description': instance.itemDescription,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'total_price': instance.totalPrice,
      'options': instance.options,
    };

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
    );

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone_number': instance.phoneNumber,
    };

DriverDto _$DriverDtoFromJson(Map<String, dynamic> json) => DriverDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String?,
    );

Map<String, dynamic> _$DriverDtoToJson(DriverDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone_number': instance.phoneNumber,
    };

OrderPartnerDto _$OrderPartnerDtoFromJson(Map<String, dynamic> json) =>
    OrderPartnerDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
    );

Map<String, dynamic> _$OrderPartnerDtoToJson(OrderPartnerDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'logo_url': instance.logoUrl,
    };

ServiceDto _$ServiceDtoFromJson(Map<String, dynamic> json) => ServiceDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      slug: json['slug'] as String?,
    );

Map<String, dynamic> _$ServiceDtoToJson(ServiceDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
    };
