import 'package:json_annotation/json_annotation.dart';
import 'partner_dto.dart';

part 'partner_response_dto.g.dart';

@JsonSerializable()
class PartnerResponseDto {
  final bool success;
  final PartnerDto? data;
  final String? message;
  final String? error;

  PartnerResponseDto({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory PartnerResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PartnerResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PartnerResponseDtoToJson(this);

  factory PartnerResponseDto.withError(String errorMessage) {
    return PartnerResponseDto(
      success: false,
      data: null,
      error: errorMessage,
    );
  }
}
