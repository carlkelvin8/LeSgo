import 'package:json_annotation/json_annotation.dart';
import 'address_dto.dart';

part 'address_response_dto.g.dart';

@JsonSerializable()
class AddressResponseDto {
  final bool success;
  final AddressDto? data;
  final String? message;
  final String? error;

  AddressResponseDto({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory AddressResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AddressResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AddressResponseDtoToJson(this);

  factory AddressResponseDto.withError(String errorMessage) {
    return AddressResponseDto(
      success: false,
      data: null,
      error: errorMessage,
    );
  }
}
