import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../di/injection.dart';
import '../network/dio_client.dart';
import '../utils/api_error_mapper.dart';
import '../utils/wallet_response_parser.dart';

/// Merchant LesPay wallet API (shared user wallet endpoints).
class MerchantWalletApi {
  MerchantWalletApi._();

  static Dio get _dio => getIt<DioClient>().dio;

  static Future<Map<String, dynamic>> getWallet() async {
    final response = await _dio.get('/v1/wallets/my/wallet');
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'] ?? body;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    return {};
  }

  static Future<List<Map<String, dynamic>>> getTransactions({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      '/v1/wallets/my/transactions',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return WalletResponseParser.parseListBody(response.data)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<Map<String, dynamic>> createTopUpInvoice({
    required double amount,
  }) async {
    final response = await _dio.post(
      '/v1/wallets/my/topup',
      data: {
        'amount': amount,
        'payment_method': 'xendit',
      },
    );
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return Map<String, dynamic>.from(body['data'] as Map? ?? body);
    }
    return {};
  }

  /// Transfer from merchant LesPay to a rider LesPay account.
  /// Backend deducts LesGo commission before crediting the rider.
  static Future<Map<String, dynamic>> transferToRider({
    required String recipientEmail,
    required double amount,
    String? note,
  }) async {
    final response = await _dio.post(
      ApiConstants.walletTransferToRider,
      data: {
        'recipient_email': recipientEmail.trim(),
        'amount': amount,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'transfer_type': 'merchant_to_rider',
      },
    );
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return Map<String, dynamic>.from(body['data'] as Map? ?? body);
    }
    return {};
  }

  static String extractError(Object error) => ApiErrorMapper.message(error);
}
