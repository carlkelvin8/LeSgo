import 'package:json_annotation/json_annotation.dart';
import 'payment_dto.dart';

part 'payments_response_dto.g.dart';

@JsonSerializable()
class PaymentMetaDto {
  @JsonKey(name: 'current_page')
  final int currentPage;
  @JsonKey(name: 'last_page')
  final int lastPage;
  @JsonKey(name: 'per_page')
  final int perPage;
  final int total;

  PaymentMetaDto({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaymentMetaDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentMetaDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentMetaDtoToJson(this);
}

@JsonSerializable()
class PaymentLinksDto {
  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  PaymentLinksDto({
    this.first,
    this.last,
    this.prev,
    this.next,
  });

  factory PaymentLinksDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentLinksDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentLinksDtoToJson(this);
}

@JsonSerializable()
class PaymentsResponseDto {
  final bool success;
  final String? error;
  final List<PaymentDto>? data;
  final PaymentMetaDto? meta;
  final PaymentLinksDto? links;

  PaymentsResponseDto({
    required this.success,
    this.error,
    this.data,
    this.meta,
    this.links,
  });

  factory PaymentsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentsResponseDtoToJson(this);
}
