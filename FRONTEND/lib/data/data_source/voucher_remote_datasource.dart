import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/voucher/available_vouchers_response_dto.dart';
import 'dto/voucher/validate_voucher_request_dto.dart';
import 'dto/voucher/validate_voucher_response_dto.dart'
    show ValidateVoucherDataDto, ValidateVoucherResponseDto;

@lazySingleton
class VoucherRemoteDataSource {
  final DioClient _dioClient;

  VoucherRemoteDataSource(this._dioClient);

  Future<AvailableVouchersResponseDto> getAvailableVouchers() async {
    final response = await _dioClient.dio.get(ApiConstants.vouchersAvailable);
    return AvailableVouchersResponseDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> claimVoucher(String voucherCode) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.vouchersClaim,
        data: {'voucher_code': voucherCode},
      );
    } on DioException catch (e) {
      final message = _extractServerMessage(e);
      throw Exception(message);
    }
  }

  String _extractServerMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      final error = data['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    return 'Unable to claim this voucher.';
  }

  Future<ValidateVoucherResponseDto> validateVoucher(
    ValidateVoucherRequestDto request,
  ) async {
    final response = await _dioClient.dio.post(
      '/v1/vouchers/validate',
      data: request.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    if (body['data'] is Map<String, dynamic> &&
        body['data'].containsKey('valid')) {
      return ValidateVoucherResponseDto(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String? ?? '',
        data: ValidateVoucherDataDto.fromJson(
          body['data'] as Map<String, dynamic>,
        ),
      );
    }
    return ValidateVoucherResponseDto.fromJson(body);
  }
}
