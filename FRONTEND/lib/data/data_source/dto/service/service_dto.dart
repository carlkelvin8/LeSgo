import 'package:json_annotation/json_annotation.dart';

part 'service_dto.g.dart';

@JsonSerializable()
class ServiceDto {
  final int id;
  final String name;
  final String code;
  final String description;
  @JsonKey(name: 'base_fare')
  final double baseFare;
  @JsonKey(name: 'per_km_rate')
  final double perKmRate;
  @JsonKey(name: 'minimum_fare')
  final double minimumFare;
  @JsonKey(name: 'icon_url')
  final String? iconUrl;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  ServiceDto({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.baseFare,
    required this.perKmRate,
    required this.minimumFare,
    this.iconUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceDto.fromJson(Map<String, dynamic> json) =>
      _$ServiceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceDtoToJson(this);
}
