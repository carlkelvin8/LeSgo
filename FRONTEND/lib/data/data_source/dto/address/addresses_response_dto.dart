import 'package:json_annotation/json_annotation.dart';
import 'address_dto.dart';

part 'addresses_response_dto.g.dart';

@JsonSerializable()
class AddressesResponseDto {
  final bool success;
  final List<AddressDto> data;
  final String? error;

  AddressesResponseDto({
    required this.success,
    required this.data,
    this.error,
  });

  factory AddressesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AddressesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AddressesResponseDtoToJson(this);

  factory AddressesResponseDto.withError(String errorMessage) {
    return AddressesResponseDto(
      success: false,
      data: [],
      error: errorMessage,
    );
  }
}
