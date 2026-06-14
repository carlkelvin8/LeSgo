import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/wallet_response_parser.dart';

class MerchantWalletState {
  final double balance;
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> transactions;

  const MerchantWalletState({
    this.balance = 0.0,
    this.isLoading = false,
    this.error,
    this.transactions = const [],
  });

  String get balanceFormatted => 'PHP ${balance.toStringAsFixed(2)}';

  MerchantWalletState copyWith({
    double? balance,
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? transactions,
    bool clearError = false,
  }) {
    return MerchantWalletState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      transactions: transactions ?? this.transactions,
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

      state = state.copyWith(
        balance: balance,
        transactions: transactions,
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

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    try {
      final path = await _transactionsPath();
      final response = await ApiService.dio.get(path);
      final items = WalletResponseParser.parseListBody(response.data)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      items.sort((a, b) {
        final aDate = a['created_at']?.toString() ?? '';
        final bDate = b['created_at']?.toString() ?? '';
        return bDate.compareTo(aDate);
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
