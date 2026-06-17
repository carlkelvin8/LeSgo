import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/lespay_topup_fee.dart';
import '../../../../core/utils/wallet_response_parser.dart';

class MerchantTopUpCheckout {
  final String invoiceId;
  final String invoiceUrl;
  final double walletAmount;
  final double feeAmount;
  final double totalCharge;

  const MerchantTopUpCheckout({
    required this.invoiceId,
    required this.invoiceUrl,
    required this.walletAmount,
    required this.feeAmount,
    required this.totalCharge,
  });
}

class MerchantWalletState {
  final double balance;
  final bool isLoading;
  final bool isProcessingTopUp;
  final String? error;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> linkedAccounts;

  const MerchantWalletState({
    this.balance = 0.0,
    this.isLoading = false,
    this.isProcessingTopUp = false,
    this.error,
    this.transactions = const [],
    this.linkedAccounts = const [],
  });

  String get balanceFormatted => 'PHP ${balance.toStringAsFixed(2)}';

  bool isProviderLinked(String provider) {
    for (final account in linkedAccounts) {
      if (account['provider']?.toString() == provider) return true;
    }
    return false;
  }

  MerchantWalletState copyWith({
    double? balance,
    bool? isLoading,
    bool? isProcessingTopUp,
    String? error,
    List<Map<String, dynamic>>? transactions,
    List<Map<String, dynamic>>? linkedAccounts,
    bool clearError = false,
  }) {
    return MerchantWalletState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      isProcessingTopUp: isProcessingTopUp ?? this.isProcessingTopUp,
      error: clearError ? null : (error ?? this.error),
      transactions: transactions ?? this.transactions,
      linkedAccounts: linkedAccounts ?? this.linkedAccounts,
    );
  }
}

class MerchantWalletNotifier extends StateNotifier<MerchantWalletState> {
  MerchantWalletNotifier() : super(const MerchantWalletState()) {
    loadWallet();
  }

  Future<void> loadWallet({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final walletResponse = await ApiService.dio.get('/v1/wallets/my/wallet');
      final wallet = (walletResponse.data['data'] ?? walletResponse.data)
          as Map<String, dynamic>;
      final balance = _toDouble(wallet['balance']);
      final transactions = await _fetchTransactions();
      final linked = await getLinkedAccounts();

      state = state.copyWith(
        balance: balance,
        transactions: transactions,
        linkedAccounts: linked,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load e-wallet. Pull to retry.',
          fallbackTl: 'Hindi ma-load ang e-wallet. Subukan muli.',
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> getLinkedAccounts() async {
    try {
      final response = await ApiService.dio.get('/v1/wallets/my/linked-accounts');
      return WalletResponseParser.parseListBody(response.data)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('Merchant linked accounts load failed: $e');
      return state.linkedAccounts;
    }
  }

  Future<MerchantTopUpCheckout?> startTopUp(double walletAmount) async {
    state = state.copyWith(isProcessingTopUp: true, clearError: true);
    try {
      final pricing = LespayTopupFee.calculate(walletAmount);
      final response = await ApiService.dio.post(
        '/v1/wallets/my/topup',
        data: {
          'amount': pricing.walletAmount,
          'payment_method': 'xendit',
        },
      );
      final checkout = _checkoutFromResponse(response.data, pricing);
      state = state.copyWith(isProcessingTopUp: false);
      return checkout;
    } catch (e) {
      state = state.copyWith(
        isProcessingTopUp: false,
        error: ApiErrorMapper.message(e),
      );
      return null;
    }
  }

  Future<bool> completeTopUp(MerchantTopUpCheckout checkout) async {
    state = state.copyWith(isProcessingTopUp: true, clearError: true);
    try {
      final response = await ApiService.dio.post(
        '/v1/wallets/my/topup/confirm',
        data: {
          'xendit_invoice_id': checkout.invoiceId,
          'amount': checkout.walletAmount,
        },
      );

      // Verify response contains updated balance
      final data = response.data as Map<String, dynamic>?;
      if (data == null || (data['success'] != true && data['data'] == null)) {
        throw Exception('TopUp confirmation failed: Invalid response');
      }

      // Try to get new balance from response
      final newBalanceFromResponse = data['wallet_balance'] ??
          (data['data'] is Map ? data['data']['balance'] : null);

      if (newBalanceFromResponse != null) {
        // Direct update to avoid extra API call
        final newBalance = _toDouble(newBalanceFromResponse);
        state = state.copyWith(
          balance: newBalance,
          isProcessingTopUp: false,
        );
      } else {
        // Fallback: reload wallet from API
        await loadWallet();
        state = state.copyWith(isProcessingTopUp: false);
      }

      return true;
    } catch (e) {
      debugPrint('Complete topup failed: $e');
      state = state.copyWith(
        isProcessingTopUp: false,
        error: ApiService.extractError(e),
      );
      return false;
    }
  }

  Future<bool> withdraw(double amount, String method) async {
    state = state.copyWith(clearError: true);
    try {
      final response = await ApiService.dio.post('/v1/wallets/my/withdraw', data: {
        'amount': amount,
        'withdrawal_method': method,
      });
      final raw = response.data;
      if (raw is Map) {
        final data = raw['data'];
        final walletData = data is Map ? (data['wallet'] ?? data) : null;
        if (walletData is Map) {
          state = state.copyWith(
            balance: _toDouble(walletData['balance']),
            clearError: true,
          );
          return true;
        }
      }
      await loadWallet();
      return true;
    } catch (e) {
      state = state.copyWith(error: ApiService.extractError(e));
      return false;
    }
  }

  MerchantTopUpCheckout? _checkoutFromResponse(
    dynamic raw,
    LespayTopupFee pricing,
  ) {
    final invoice = WalletResponseParser.extractInvoiceMap(raw);
    if (invoice == null) return null;

    final invoiceId = invoice['invoice_id']?.toString() ?? invoice['id']?.toString();
    final invoiceUrl = invoice['invoice_url']?.toString();
    if (invoiceId == null ||
        invoiceId.isEmpty ||
        invoiceUrl == null ||
        invoiceUrl.isEmpty) {
      return null;
    }

    return MerchantTopUpCheckout(
      invoiceId: invoiceId,
      invoiceUrl: invoiceUrl,
      walletAmount: pricing.walletAmount,
      feeAmount: pricing.feeAmount,
      totalCharge: pricing.totalCharge,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    try {
      final path = await _transactionsPath();
      final response = await ApiService.dio.get(path);
      final items = WalletResponseParser.parseListBody(response.data)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      items.sort((a, b) {
        try {
          final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        } catch (e) {
          debugPrint('Error sorting transactions: $e');
          return 0;
        }
      });
      return items;
    } catch (e) {
      debugPrint('Merchant wallet transactions load failed: $e');
      return state.transactions;
    }
  }

  Future<String> _transactionsPath() async {
    final userId = await SecureStorageService.getUserId();
    if (userId != null) {
      return '/v1/wallets/$userId/transactions';
    }

    try {
      final me = await ApiService.getMe();
      final data = me['data'] ?? me['user'] ?? me;
      if (data is Map && data['id'] != null) {
        return '/v1/wallets/${data['id']}/transactions';
      }
    } catch (e) {
      debugPrint('Could not resolve merchant user id for transactions: $e');
    }

    return '/v1/wallets/my/transactions';
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

final merchantWalletProvider =
    StateNotifierProvider<MerchantWalletNotifier, MerchantWalletState>(
  (ref) => MerchantWalletNotifier(),
);
