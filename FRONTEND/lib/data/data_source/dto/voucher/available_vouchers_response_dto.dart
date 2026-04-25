import 'package:json_annotation/json_annotation.dart';
import 'voucher_dto.dart';

part 'available_vouchers_response_dto.g.dart';

@JsonSerializable()
class AvailableVouchersResponseDto {
  final bool success;
  final String message;
  final List<VoucherDto> data;

  AvailableVouchersResponseDto({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AvailableVouchersResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AvailableVouchersResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AvailableVouchersResponseDtoToJson(this);
}
