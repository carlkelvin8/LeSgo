// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentDto _$PaymentDtoFromJson(Map<String, dynamic> json) => PaymentDto(
  id: (json['id'] as num).toInt(),
  orderId: (json['order_id'] as num).toInt(),
  customerId: (json['customer_id'] as num).toInt(),
  partnerId: (json['partner_id'] as num?)?.toInt(),
  driverId: (json['driver_id'] as num?)?.toInt(),
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String?,
  method: json['method'] as String,
  status: json['status'] as String,
  provider: json['provider'] as String?,
  providerReference: json['provider_reference'] as String?,
  paidAt: json['paid_at'] as String?,
  meta: json['meta'] as Map<String, dynamic>?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  order: json['order'] == null
      ? null
      : PaymentOrderDto.fromJson(json['order'] as Map<String, dynamic>),
  customer: json['customer'] == null
      ? null
      : PaymentCustomerDto.fromJson(json['customer'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PaymentDtoToJson(PaymentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'customer_id': instance.customerId,
      'partner_id': instance.partnerId,
      'driver_id': instance.driverId,
      'amount': instance.amount,
      'currency': instance.currency,
      'method': instance.method,
      'status': instance.status,
      'provider': instance.provider,
      'provider_reference': instance.providerReference,
      'paid_at': instance.paidAt,
      'meta': instance.meta,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'order': instance.order,
      'customer': instance.customer,
    };

PaymentOrderDto _$PaymentOrderDtoFromJson(Map<String, dynamic> json) =>
    PaymentOrderDto(
      id: (json['id'] as num).toInt(),
      customerId: (json['customer_id'] as num).toInt(),
      serviceId: (json['service_id'] as num).toInt(),
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String,
      estimatedFare: (json['estimated_fare'] as num).toDouble(),
      actualFare: (json['actual_fare'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PaymentOrderDtoToJson(PaymentOrderDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customer_id': instance.customerId,
      'service_id': instance.serviceId,
      'status': instance.status,
      'payment_method': instance.paymentMethod,
      'estimated_fare': instance.estimatedFare,
      'actual_fare': instance.actualFare,
    };

PaymentCustomerDto _$PaymentCustomerDtoFromJson(Map<String, dynamic> json) =>
    PaymentCustomerDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
    );

Map<String, dynamic> _$PaymentCustomerDtoToJson(PaymentCustomerDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone_number': instance.phoneNumber,
    };
