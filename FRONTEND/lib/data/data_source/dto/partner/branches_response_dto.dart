import 'package:json_annotation/json_annotation.dart';
import 'branch_dto.dart';
import '../service/services_response_dto.dart'; // For MetaDto

part 'branches_response_dto.g.dart';

@JsonSerializable()
class BranchesResponseDto {
  final bool success;
  final List<BranchDto> data;
  final MetaDto meta;
  final String? error;

  BranchesResponseDto({
    required this.success,
    required this.data,
    required this.meta,
    this.error,
  });

  factory BranchesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$BranchesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BranchesResponseDtoToJson(this);

  factory BranchesResponseDto.withError(String errorMessage) {
    return BranchesResponseDto(
      success: false,
      data: [],
      meta: MetaDto(currentPage: 1, lastPage: 1, perPage: 20, total: 0),
      error: errorMessage,
    );
  }
}
