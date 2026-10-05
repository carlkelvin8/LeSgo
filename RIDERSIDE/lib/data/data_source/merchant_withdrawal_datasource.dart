import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import 'dto/merchant/withdrawal_request_dto.dart';

class MerchantWithdrawalDataSource {
  MerchantWithdrawalDataSource({Dio? dio}) : _client = dio;

  final Dio? _client;
  Dio get _dio => _client ?? ApiService.dio;

  /// Get withdrawal summary (balances, limits, statistics)
  Future<WithdrawalSummaryDto> getSummary() async {
    try {
      final response = await _dio.get('/v1/merchant/withdrawals/summary');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        final summaryResponse = WithdrawalSummaryResponseDto.fromJson(data);
        return summaryResponse.data;
      }

      throw Exception('Invalid summary response');
    } catch (e) {
      throw Exception(
          'Failed to fetch withdrawal summary: ${ApiService.extractError(e)}');
    }
  }

  /// Get list of withdrawal requests with optional status filter
  Future<WithdrawalPaginationDto> getWithdrawals({
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        '/v1/merchant/withdrawals',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        final listResponse = WithdrawalListResponseDto.fromJson(data);
        return listResponse.data;
      }

      throw Exception('Invalid withdrawal list response');
    } catch (e) {
      throw Exception(
          'Failed to fetch withdrawals: ${ApiService.extractError(e)}');
    }
  }

  /// Get a specific withdrawal request by ID
  Future<WithdrawalRequestDto> getWithdrawal(int id) async {
    try {
      final response = await _dio.get('/v1/merchant/withdrawals/$id');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        final withdrawalResponse = WithdrawalResponseDto.fromJson(data);
        if (withdrawalResponse.data != null) {
          return withdrawalResponse.data!;
        }
      }

      throw Exception('Withdrawal not found');
    } catch (e) {
      throw Exception(
          'Failed to fetch withdrawal: ${ApiService.extractError(e)}');
    }
  }

  /// Create a new withdrawal request
  Future<WithdrawalRequestDto> createWithdrawal({
    required double amount,
    required String payoutMethod,
    required String payoutAccountNumber,
    required String payoutAccountName,
    String? payoutBankName,
  }) async {
    try {
      final requestDto = CreateWithdrawalRequestDto(
        amount: amount,
        payoutMethod: payoutMethod,
        payoutAccountNumber: payoutAccountNumber,
        payoutAccountName: payoutAccountName,
        payoutBankName: payoutBankName,
      );

      final response = await _dio.post(
        '/v1/merchant/withdrawals',
        data: requestDto.toJson(),
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        final withdrawalResponse = WithdrawalResponseDto.fromJson(data);
        if (withdrawalResponse.data != null) {
          return withdrawalResponse.data!;
        }
      }

      // Handle error message from API
      final message = data['message'] as String?;
      throw Exception(message ?? 'Failed to create withdrawal request');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        // Validation error
        final data = e.response?.data as Map<String, dynamic>?;
        final message = data?['message'] as String?;
        throw Exception(message ?? 'Validation failed');
      }
      throw Exception(
          'Failed to create withdrawal: ${ApiService.extractError(e)}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to create withdrawal: $e');
    }
  }

  /// Cancel a pending withdrawal request
  Future<WithdrawalRequestDto> cancelWithdrawal(int id) async {
    try {
      final response = await _dio.post('/v1/merchant/withdrawals/$id/cancel');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        final withdrawalResponse = WithdrawalResponseDto.fromJson(data);
        if (withdrawalResponse.data != null) {
          return withdrawalResponse.data!;
        }
      }

      throw Exception('Failed to cancel withdrawal');
    } catch (e) {
      throw Exception(
          'Failed to cancel withdrawal: ${ApiService.extractError(e)}');
    }
  }
}
