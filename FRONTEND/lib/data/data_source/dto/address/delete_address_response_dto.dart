import 'package:json_annotation/json_annotation.dart';

part 'delete_address_response_dto.g.dart';

@JsonSerializable()
class DeleteAddressResponseDto {
  final bool success;
  final String? message;
  final String? error;

  DeleteAddressResponseDto({
    required this.success,
    this.message,
    this.error,
  });

  factory DeleteAddressResponseDto.fromJson(Map<String, dynamic> json) =>
      _$DeleteAddressResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteAddressResponseDtoToJson(this);

  factory DeleteAddressResponseDto.withError(String errorMessage) {
    return DeleteAddressResponseDto(
      success: false,
      error: errorMessage,
    );
  }
}
