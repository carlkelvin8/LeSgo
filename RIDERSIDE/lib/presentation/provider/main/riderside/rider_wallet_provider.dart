import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/api_service.dart';

class RiderWalletState {
  final double balance;
  final double deposit; // total earnings / deposited amount
  final bool isLoading;
  final String? error;

  const RiderWalletState({
    this.balance = 0.0,
    this.deposit = 0.0,
    this.isLoading = false,
    this.error,
  });

  String get balanceFormatted => 'PHP ${balance.toStringAsFixed(2)}';
  String get depositFormatted => 'PHP ${deposit.toStringAsFixed(2)}';

  RiderWalletState copyWith({
    double? balance,
    double? deposit,
    bool? isLoading,
    String? error,
  }) {
    return RiderWalletState(
      balance: balance ?? this.balance,
      deposit: deposit ?? this.deposit,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RiderWalletNotifier extends StateNotifier<RiderWalletState> {
  RiderWalletNotifier() : super(const RiderWalletState()) {
    loadWallet();
  }

  Future<void> loadWallet() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await ApiService.dio.get('/v1/wallets/my/wallet');
      final wallet = (data.data['data'] ?? data.data) as Map<String, dynamic>;

      final balance = _d(wallet['balance']);

      // Fetch transactions to compute total credited (deposit)
      double deposit = 0.0;
      try {
        final txData = await ApiService.dio.get(
          '/v1/wallets/my/transactions',
          queryParameters: {'type': 'credit'},
        );
        final txList = txData.data['data'] as List<dynamic>? ?? [];
        deposit = txList.fold(
          0.0,
          (sum, tx) => sum + _d((tx as Map<String, dynamic>)['amount']),
        );
      } catch (_) {
        // deposit stays 0 if transactions fail
      }

      state = state.copyWith(
        balance: balance,
        deposit: deposit,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiService.extractError(e),
      );
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final response = await ApiService.dio.get('/v1/wallets/my/transactions');
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> topUp(double amount, String method) async {
    try {
      await ApiService.dio.post('/v1/wallets/my/topup', data: {
        'amount': amount,
        'payment_method': method,
      });
      await loadWallet();
      return true;
    } catch (e) {
      state = state.copyWith(error: ApiService.extractError(e));
      return false;
    }
  }

  Future<bool> withdraw(double amount, String method) async {
    try {
      await ApiService.dio.post('/v1/wallets/my/withdraw', data: {
        'amount': amount,
        'withdrawal_method': method,
      });
      await loadWallet();
      return true;
    } catch (e) {
      state = state.copyWith(error: ApiService.extractError(e));
      return false;
    }
  }

  double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

final riderWalletProvider =
    StateNotifierProvider<RiderWalletNotifier, RiderWalletState>(
      (ref) => RiderWalletNotifier(),
    );
