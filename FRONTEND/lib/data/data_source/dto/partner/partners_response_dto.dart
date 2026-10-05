import 'package:json_annotation/json_annotation.dart';
import 'partner_dto.dart';
import '../service/services_response_dto.dart'; // For MetaDto

part 'partners_response_dto.g.dart';

@JsonSerializable()
class PartnersResponseDto {
  final bool success;
  final List<PartnerDto> data;
  final MetaDto meta;
  final String? error;

  PartnersResponseDto({
    required this.success,
    required this.data,
    required this.meta,
    this.error,
  });

  factory PartnersResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PartnersResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PartnersResponseDtoToJson(this);

  factory PartnersResponseDto.withError(String errorMessage) {
    return PartnersResponseDto(
      success: false,
      data: [],
      meta: MetaDto(currentPage: 1, lastPage: 1, perPage: 20, total: 0),
      error: errorMessage,
    );
  }
}
