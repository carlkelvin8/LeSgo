import 'package:injectable/injectable.dart';

import '../../core/network/dio_client.dart';

@lazySingleton
class PayMongoRemoteDataSource {
  final DioClient _dioClient;

  PayMongoRemoteDataSource(this._dioClient);

  /// Creates a checkout session via the backend API.
  /// Returns the invoice/checkout data including checkout_url.
  Future<Map<String, dynamic>> createCheckoutSession({
    required double amount,
    required String description,
    String? paymentMethod,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _dioClient.dio.post(
      '/v1/payment-gateway/invoices',
      data: {
        'amount': amount,
        'description': description,
        'payment_method': paymentMethod ?? 'paymongo',
        'metadata': {
          'type': 'wallet_topup',
          'provider': 'paymongo',
          ...?metadata,
        },
      },
    );
    final body = response.data as Map<String, dynamic>;
    return (body['data'] as Map<String, dynamic>?) ?? body;
  }

  /// Verify checkout session status via the backend API.
  Future<Map<String, dynamic>> getCheckoutSession(String sessionId) async {
    final response = await _dioClient.dio.get(
      '/v1/payment-gateway/invoices/$sessionId',
    );
    final body = response.data as Map<String, dynamic>;
    return (body['data'] as Map<String, dynamic>?) ?? body;
  }
}
