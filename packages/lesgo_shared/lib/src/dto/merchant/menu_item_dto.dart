import 'package:json_annotation/json_annotation.dart';

part 'menu_item_dto.g.dart';

@JsonSerializable()
class SharedMenuItemDto {
  final int? id;
  @JsonKey(name: 'partner_id')
  final int? partnerId;
  final String? name;
  final String? description;
  final double? price;
  @JsonKey(name: 'sale_price')
  final double? salePrice;
  final String? image;
  final String? category;
  @JsonKey(name: 'is_available')
  final bool? isAvailable;
  @JsonKey(name: 'is_featured')
  final bool? isFeatured;
  @JsonKey(name: 'preparation_time')
  final int? preparationTime;

  const SharedMenuItemDto({
    this.id,
    this.partnerId,
    this.name,
    this.description,
    this.price,
    this.salePrice,
    this.image,
    this.category,
    this.isAvailable,
    this.isFeatured,
    this.preparationTime,
  });

  factory SharedMenuItemDto.fromJson(Map<String, dynamic> json) =>
      _$SharedMenuItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SharedMenuItemDtoToJson(this);
}
