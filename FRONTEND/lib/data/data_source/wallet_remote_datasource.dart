import 'package:injectable/injectable.dart';

import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import 'dto/wallet/wallet_dto.dart';

@lazySingleton
class WalletRemoteDataSource {
  final DioClient _dioClient;

  WalletRemoteDataSource(this._dioClient);

  Future<WalletDto> getMyWallet() async {
    final response = await _dioClient.dio.get('/v1/wallets/my/wallet');
    return _parseWallet(response.data);
  }

  Future<String> _transactionsPath() async {
    try {
      final response = await _dioClient.dio.get('/v1/auth/me');
      final raw = response.data;
      if (raw is Map) {
        final data = raw['data'] ?? raw['user'] ?? raw;
        if (data is Map && data['id'] != null) {
          return '/v1/wallets/${data['id']}/transactions';
        }
      }
    } catch (_) {}
    return '/v1/wallets/my/transactions';
  }

  Future<List<WalletTransactionDto>> getMyTransactions({String? type}) async {
    final path = await _transactionsPath();
    final response = await _dioClient.dio.get(
      path,
      queryParameters: type != null ? {'type' : type} : null,
    );
    final data = response.data;
    final list = (data is Map ? data['data'] : data) as List<dynamic>? ?? [];
    return list
        .map((e) => WalletTransactionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a payment checkout invoice for LesPay top-up.
  /// [provider] defaults to 'paymongo'. Use 'xendit' for fallback.
  Future<Map<String, dynamic>> createTopUpInvoice({
    required double amount,
    String paymentMethod = 'paymongo',
    String? provider,
  }) async {
    final response = await _dioClient.dio.post(
      '/v1/wallets/my/topup',
      data: {
        'amount': amount,
        'payment_method': paymentMethod,
        if (provider != null) 'provider': provider,
      },
    );
    final body = response.data as Map<String, dynamic>;
    return (body['data'] as Map<String, dynamic>?) ?? body;
  }

  /// Verifies payment and credits wallet (call after user pays).
  Future<void> confirmTopUp({
    required double amount,
    required String paymentMethod,
    String? gatewayReference,
    String? xenditInvoiceId,
    String? externalReference,
  }) async {
    await _dioClient.dio.post(
      '/v1/wallets/my/topup',
      data: {
        'amount': amount,
        'payment_method': paymentMethod,
        if (gatewayReference != null) 'gateway_reference': gatewayReference,
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

  Future<List<Map<String, dynamic>>> getLinkedAccounts() async {
    final response =
        await _dioClient.dio.get(ApiConstants.walletLinkedAccounts);
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  Future<Map<String, dynamic>> linkAccount({
    required String provider,
    String? accountLabel,
    String? accountLast4,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.walletLinkedAccounts,
      data: {
        'provider': provider,
        if (accountLabel != null) 'account_label': accountLabel,
        if (accountLast4 != null) 'account_last4': accountLast4,
      },
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<void> verifyLinkedAccount(String provider) async {
    await _dioClient.dio.post(
      ApiConstants.walletLinkedAccountVerify(provider),
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
