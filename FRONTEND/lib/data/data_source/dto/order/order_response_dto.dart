import 'package:json_annotation/json_annotation.dart';
import 'order_dto.dart';

part 'order_response_dto.g.dart';

@JsonSerializable()
class OrderResponseDto {
  final bool success;
  final String message;
  final OrderDto? order;
  final List<OrderDto>? orders;
  final PaginationDto? pagination;

  OrderResponseDto({
    required this.success,
    required this.message,
    this.order,
    this.orders,
    this.pagination,
  });

  factory OrderResponseDto.fromJson(Map<String, dynamic> json) =>
      _$OrderResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderResponseDtoToJson(this);
}

@JsonSerializable()
class PaginationDto {
  @JsonKey(name: 'current_page')
  final int currentPage;
  @JsonKey(name: 'last_page')
  final int lastPage;
  @JsonKey(name: 'per_page')
  final int perPage;
  final int total;

  PaginationDto({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationDto.fromJson(Map<String, dynamic> json) =>
      _$PaginationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationDtoToJson(this);
}
