import 'package:injectable/injectable.dart';

import '../../core/network/dio_client.dart';
import 'dto/voucher/available_vouchers_response_dto.dart';
import 'dto/voucher/validate_voucher_request_dto.dart';
import 'dto/voucher/validate_voucher_response_dto.dart';

@lazySingleton
class VoucherRemoteDataSource {
  final DioClient _dioClient;

  VoucherRemoteDataSource(this._dioClient);

  Future<AvailableVouchersResponseDto> getAvailableVouchers() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/vouchers/available');
      return AvailableVouchersResponseDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to get available vouchers: $e');
    }
  }

  Future<ValidateVoucherResponseDto> validateVoucher(
    ValidateVoucherRequestDto request,
  ) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post(
        '/v1/vouchers/validate',
        data: request.toJson(),
      );
      return ValidateVoucherResponseDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to validate voucher: $e');
    }
  }
}
