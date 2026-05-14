import 'package:json_annotation/json_annotation.dart';

part 'lesbuy_item_dto.g.dart';

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
class LesbuyItemDto {
  final int id;
  @JsonKey(name: 'order_id')
  final int orderId;
  final String name;
  final int quantity;
  final String? unit;
  final String? notes;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'estimated_price', fromJson: _parseDoubleNullable)
  final double? estimatedPrice;
  @JsonKey(name: 'actual_price', fromJson: _parseDoubleNullable)
  final double? actualPrice;

  LesbuyItemDto({
    required this.id,
    required this.orderId,
    required this.name,
    required this.quantity,
    this.unit,
    this.notes,
    this.imageUrl,
    this.estimatedPrice,
    this.actualPrice,
  });

  factory LesbuyItemDto.fromJson(Map<String, dynamic> json) =>
      _$LesbuyItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LesbuyItemDtoToJson(this);
}