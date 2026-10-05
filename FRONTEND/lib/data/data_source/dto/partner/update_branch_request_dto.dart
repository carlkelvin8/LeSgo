import 'package:json_annotation/json_annotation.dart';

part 'update_branch_request_dto.g.dart';

@JsonSerializable()
class UpdateBranchRequestDto {
  final String? name;
  final String? address;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'is_open')
  final bool? isOpen;
  @JsonKey(name: 'operating_hours')
  final String? operatingHours;

  UpdateBranchRequestDto({
    this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.isOpen,
    this.operatingHours,
  });

  factory UpdateBranchRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateBranchRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateBranchRequestDtoToJson(this);
}
