import 'package:json_annotation/json_annotation.dart';

part 'create_branch_request_dto.g.dart';

@JsonSerializable()
class CreateBranchRequestDto {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  @JsonKey(name: 'is_open')
  final bool isOpen;
  @JsonKey(name: 'operating_hours')
  final String operatingHours;

  CreateBranchRequestDto({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isOpen,
    required this.operatingHours,
  });

  factory CreateBranchRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateBranchRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateBranchRequestDtoToJson(this);
}
