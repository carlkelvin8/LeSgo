import 'package:json_annotation/json_annotation.dart';
import 'order_dto.dart';

part 'orders_response_dto.g.dart';

@JsonSerializable()
class OrdersResponseDto {
  final bool success;
  final List<OrderDto> data;
  final Map<String, dynamic>? meta;
  final Map<String, dynamic>? links;

  OrdersResponseDto({
    required this.success,
    required this.data,
    this.meta,
    this.links,
  });

  factory OrdersResponseDto.fromJson(Map<String, dynamic> json) =>
      _$OrdersResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrdersResponseDtoToJson(this);
}

@JsonSerializable()
class OrderResponseDto {
  final bool success;
  final String? message;
  final OrderDto data;

  OrderResponseDto({
    required this.success,
    this.message,
    required this.data,
  });

  factory OrderResponseDto.fromJson(Map<String, dynamic> json) =>
      _$OrderResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderResponseDtoToJson(this);
}
