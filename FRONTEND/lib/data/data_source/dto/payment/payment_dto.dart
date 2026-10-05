import 'package:json_annotation/json_annotation.dart';

part 'payment_dto.g.dart';

@JsonSerializable()
class PaymentDto {
  final int id;
  @JsonKey(name: 'order_id')
  final int orderId;
  @JsonKey(name: 'customer_id')
  final int customerId;
  @JsonKey(name: 'partner_id')
  final int? partnerId;
  @JsonKey(name: 'driver_id')
  final int? driverId;
  final double amount;
  final String? currency;
  final String method;
  final String status;
  final String? provider;
  @JsonKey(name: 'provider_reference')
  final String? providerReference;
  @JsonKey(name: 'paid_at')
  final String? paidAt;
  final Map<String, dynamic>? meta;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final PaymentOrderDto? order;
  final PaymentCustomerDto? customer;

  PaymentDto({
    required this.id,
    required this.orderId,
    required this.customerId,
    this.partnerId,
    this.driverId,
    required this.amount,
    this.currency,
    required this.method,
    required this.status,
    this.provider,
    this.providerReference,
    this.paidAt,
    this.meta,
    this.createdAt,
    this.updatedAt,
    this.order,
    this.customer,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentDtoToJson(this);
}

@JsonSerializable()
class PaymentOrderDto {
  final int id;
  @JsonKey(name: 'customer_id')
  final int customerId;
  @JsonKey(name: 'service_id')
  final int serviceId;
  final String status;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'estimated_fare')
  final double estimatedFare;
  @JsonKey(name: 'actual_fare')
  final double? actualFare;

  PaymentOrderDto({
    required this.id,
    required this.customerId,
    required this.serviceId,
    required this.status,
    required this.paymentMethod,
    required this.estimatedFare,
    this.actualFare,
  });

  factory PaymentOrderDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentOrderDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentOrderDtoToJson(this);
}

@JsonSerializable()
class PaymentCustomerDto {
  final int id;
  final String name;
  final String email;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;

  PaymentCustomerDto({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
  });

  factory PaymentCustomerDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentCustomerDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentCustomerDtoToJson(this);
}
