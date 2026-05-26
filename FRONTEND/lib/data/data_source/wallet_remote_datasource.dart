import 'package:injectable/injectable.dart';

import '../../core/network/dio_client.dart';
import 'dto/wallet/wallet_dto.dart';

@lazySingleton
class WalletRemoteDataSource {
  final DioClient _dioClient;

  WalletRemoteDataSource(this._dioClient);

  Future<WalletDto> getMyWallet() async {
    final response = await _dioClient.dio.get('/v1/wallets/my/wallet');
    return _parseWallet(response.data);
  }

  Future<List<WalletTransactionDto>> getMyTransactions({String? type}) async {
    final response = await _dioClient.dio.get(
      '/v1/wallets/my/transactions',
      queryParameters: type != null ? {'type': type} : null,
    );
    final data = response.data;
    final list = (data is Map ? data['data'] : data) as List<dynamic>? ?? [];
    return list
        .map((e) => WalletTransactionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a Xendit checkout invoice for LesPay top-up.
  Future<Map<String, dynamic>> createTopUpInvoice({
    required double amount,
    String paymentMethod = 'xendit',
  }) async {
    final response = await _dioClient.dio.post(
      '/v1/wallets/my/topup',
      data: {
        'amount': amount,
        'payment_method': paymentMethod,
      },
    );
    final body = response.data as Map<String, dynamic>;
    return (body['data'] as Map<String, dynamic>?) ?? body;
  }

  /// Verifies Xendit payment and credits wallet (call after user pays).
  Future<void> confirmTopUp({
    required double amount,
    required String paymentMethod,
    String? xenditInvoiceId,
    String? externalReference,
  }) async {
    await _dioClient.dio.post(
      '/v1/wallets/my/topup',
      data: {
        'amount': amount,
        'payment_method': paymentMethod,
        if (xenditInvoiceId != null) 'xendit_invoice_id': xenditInvoiceId,
        if (externalReference != null) 'external_reference': externalReference,
      },
    );
  }

  Future<void> withdraw({
    required double amount,
    required String withdrawalMethod,
  }) async {
    await _dioClient.dio.post(
      '/v1/wallets/my/withdraw',
      data: {
        'amount': amount,
        'withdrawal_method': withdrawalMethod,
      },
    );
  }

  WalletDto _parseWallet(dynamic data) {
    final map = data is Map<String, dynamic>
        ? data
        : (data as Map).cast<String, dynamic>();
    final walletJson = map['data'] ?? map;
    return WalletDto.fromJson(walletJson as Map<String, dynamic>);
  }
}
