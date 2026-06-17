import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_logger.dart';

/// Payout provider manages wallet balance and payout requests
final riderPayoutProvider = StateNotifierProvider.autoDispose<RiderPayoutNotifier, RiderPayoutState>(
  (ref) => RiderPayoutNotifier(),
);

/// Payout history provider
final riderPayoutHistoryProvider = FutureProvider.autoDispose<List<PayoutRecord>>((ref) async {
  final notifier = ref.read(riderPayoutProvider.notifier);
  return notifier.fetchPayoutHistory();
});

class RiderPayoutNotifier extends StateNotifier<RiderPayoutState> {
  RiderPayoutNotifier() : super(const RiderPayoutState());

  Future<void> loadPayoutData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.dio.get('/v1/wallets/my/wallet');
      final data = response.data['data'] ?? response.data;

      final availableBalance = (data['balance'] as num?)?.toDouble() ?? 0.0;
      final pendingBalance = (data['pending_balance'] as num?)?.toDouble() ?? 0.0;

      state = state.copyWith(
        availableBalance: availableBalance,
        pendingBalance: pendingBalance,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('Failed to load payout data', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load wallet data',
      );
    }
  }

  Future<List<PayoutRecord>> fetchPayoutHistory() async {
    try {
      final response = await ApiService.dio.get('/v1/wallets/my/payouts');
      final data = response.data['data'] ?? response.data;
      
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => PayoutRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.error('Failed to fetch payout history', e);
      return [];
    }
  }

  Future<void> requestWithdrawal({
    required double amount,
    required String paymentMethod,
    required String accountNumber,
  }) async {
    if (amount <= 0 || amount > state.availableBalance) {
      state = state.copyWith(error: 'Invalid withdrawal amount');
      return;
    }

    state = state.copyWith(isProcessing: true, error: null);
    try {
      final response = await ApiService.dio.post(
        '/v1/wallets/my/withdraw',
        data: {
          'amount': amount,
          'payment_method': paymentMethod,
          'account_number': accountNumber,
        },
      );

      final data = response.data['data'] ?? response.data;
      final withdrawalId = data['id'] ?? '';

      // Update available balance
      state = state.copyWith(
        availableBalance: state.availableBalance - amount,
        pendingBalance: state.pendingBalance + amount,
        isProcessing: false,
      );

      AppLogger.info('Withdrawal request submitted: $withdrawalId');
    } catch (e) {
      AppLogger.error('Withdrawal request failed', e);
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to submit withdrawal request',
      );
      rethrow;
    }
  }

  Future<void> linkPaymentAccount({
    required String provider,
    required String accountNumber,
    required String accountName,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      await ApiService.dio.post(
        '/v1/wallets/my/linked-accounts',
        data: {
          'provider': provider,
          'account_number': accountNumber,
          'account_name': accountName,
        },
      );

      state = state.copyWith(isProcessing: false);
      AppLogger.info('Payment account linked: $provider');
    } catch (e) {
      AppLogger.error('Failed to link payment account', e);
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to link account',
      );
      rethrow;
    }
  }
}

class RiderPayoutState {
  final double availableBalance;
  final double pendingBalance;
  final bool isLoading;
  final bool isProcessing;
  final String? error;

  const RiderPayoutState({
    this.availableBalance = 0.0,
    this.pendingBalance = 0.0,
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
  });

  String get availableBalanceFormatted => 'PHP ${availableBalance.toStringAsFixed(2)}';
  String get pendingBalanceFormatted => 'PHP ${pendingBalance.toStringAsFixed(2)}';
  String get totalBalanceFormatted => 'PHP ${(availableBalance + pendingBalance).toStringAsFixed(2)}';

  RiderPayoutState copyWith({
    double? availableBalance,
    double? pendingBalance,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    bool clearError = false,
  }) {
    return RiderPayoutState(
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PayoutRecord {
  final String id;
  final double amount;
  final String status;
  final String paymentMethod;
  final String accountNumber;
  final DateTime requestedAt;
  final DateTime? completedAt;

  const PayoutRecord({
    required this.id,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.accountNumber,
    required this.requestedAt,
    this.completedAt,
  });

  factory PayoutRecord.fromJson(Map<String, dynamic> json) {
    return PayoutRecord(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      paymentMethod: json['payment_method']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      requestedAt: json['requested_at'] != null
          ? DateTime.parse(json['requested_at'].toString()).toLocal()
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'].toString()).toLocal()
          : null,
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isFailed => status.toLowerCase() == 'failed';

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFA500);
      case 'processing':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'failed':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF757575);
    }
  }
}
