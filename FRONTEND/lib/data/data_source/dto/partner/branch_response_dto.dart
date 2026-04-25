import 'package:json_annotation/json_annotation.dart';
import 'branch_dto.dart';

part 'branch_response_dto.g.dart';

@JsonSerializable()
class BranchResponseDto {
  final bool success;
  final BranchDto? data;
  final String? message;
  final String? error;

  BranchResponseDto({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory BranchResponseDto.fromJson(Map<String, dynamic> json) =>
      _$BranchResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BranchResponseDtoToJson(this);

  factory BranchResponseDto.withError(String errorMessage) {
    return BranchResponseDto(
      success: false,
      data: null,
      error: errorMessage,
    );
  }
}
