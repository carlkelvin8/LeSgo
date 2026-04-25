import 'package:json_annotation/json_annotation.dart';

part 'branch_dto.g.dart';

@JsonSerializable()
class BranchDto {
  final int id;
  @JsonKey(name: 'partner_id')
  final int partnerId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  @JsonKey(name: 'is_open')
  final bool isOpen;
  @JsonKey(name: 'operating_hours')
  final String operatingHours;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  BranchDto({
    required this.id,
    required this.partnerId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isOpen,
    required this.operatingHours,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BranchDto.fromJson(Map<String, dynamic> json) =>
      _$BranchDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BranchDtoToJson(this);
}
