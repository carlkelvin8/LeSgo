import 'package:json_annotation/json_annotation.dart';

part 'estimate_request_dto.g.dart';

@JsonSerializable()
class EstimateRequestDto {
  @JsonKey(name: 'service_id')
  final int serviceId;
  @JsonKey(name: 'pickup_lat')
  final double pickupLat;
  @JsonKey(name: 'pickup_lng')
  final double pickupLng;
  @JsonKey(name: 'dropoff_lat')
  final double dropoffLat;
  @JsonKey(name: 'dropoff_lng')
  final double dropoffLng;
  @JsonKey(name: 'estimated_distance_m')
  final int estimatedDistanceM;

  EstimateRequestDto({
    required this.serviceId,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.estimatedDistanceM,
  });

  factory EstimateRequestDto.fromJson(Map<String, dynamic> json) =>
      _$EstimateRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EstimateRequestDtoToJson(this);
}
