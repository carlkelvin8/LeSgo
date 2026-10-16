import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/merchant_wallet_api.dart';
import '../../../../core/utils/merchant_staff_permissions.dart';
import '../../../../core/utils/merchant_transfer_commission_utils.dart';
import '../../../../data/data_source/merchant_withdrawal_datasource.dart';
import '../../../../data/data_source/dto/merchant/withdrawal_request_dto.dart';
import '../../auth/rider_auth_provider.dart';

class MerchantTopUpCheckout {
  final String invoiceId;
  final String invoiceUrl;

  const MerchantTopUpCheckout({
    required this.invoiceId,
    required this.invoiceUrl,
  });
}

class MerchantWalletState {
  final double balance;
  final double availableBalance;
  final double pendingWithdrawals;
  final bool isLoading;
  final bool isTransferring;
  final bool isWithdrawing;
  final String? error;
  final List<Map<String, dynamic>> transactions;
  final WithdrawalSummaryDto? withdrawalSummary;

  const MerchantWalletState({
    this.balance = 0,
    this.availableBalance = 0,
    this.pendingWithdrawals = 0,
    this.isLoading = false,
    this.isTransferring = false,
    this.isWithdrawing = false,
    this.error,
    this.transactions = const [],
    this.withdrawalSummary,
  });

  String get balanceFormatted => 'PHP ${balance.toStringAsFixed(2)}';
  String get availableBalanceFormatted =>
      'PHP ${availableBalance.toStringAsFixed(2)}';
  String get pendingWithdrawalsFormatted =>
      'PHP ${pendingWithdrawals.toStringAsFixed(2)}';

  MerchantWalletState copyWith({
    double? balance,
    double? availableBalance,
    double? pendingWithdrawals,
    bool? isLoading,
    bool? isTransferring,
    bool? isWithdrawing,
    String? error,
    List<Map<String, dynamic>>? transactions,
    WithdrawalSummaryDto? withdrawalSummary,
    bool clearError = false,
  }) {
    return MerchantWalletState(
      balance: balance ?? this.balance,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingWithdrawals: pendingWithdrawals ?? this.pendingWithdrawals,
      isLoading: isLoading ?? this.isLoading,
      isTransferring: isTransferring ?? this.isTransferring,
      isWithdrawing: isWithdrawing ?? this.isWithdrawing,
      error: clearError ? null : (error ?? this.error),
      transactions: transactions ?? this.transactions,
      withdrawalSummary: withdrawalSummary ?? this.withdrawalSummary,
    );
  }
}

class MerchantWalletNotifier extends StateNotifier<MerchantWalletState> {
  MerchantWalletNotifier(this.ref) : super(const MerchantWalletState()) {
    loadWallet();
  }

  final Ref ref;
  final _withdrawalDataSource = MerchantWithdrawalDataSource();

  bool get canManageWallet {
    final user = ref.read(riderAuthProvider).user;
    if (user == null) return false;
    if (user.isMerchant) return true;
    return MerchantStaffPermissions.userCan(
      isMerchantOwner: false,
      staffRole: user.staffInfo?.role,
      explicitPermissions: user.staffInfo?.permissions,
      permission: MerchantStaffPermissions.manageWallet,
    );
  }

  Future<void> loadWallet({bool silent = false}) async {
    if (!canManageWallet) return;
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final wallet = await MerchantWalletApi.getWallet();
      final transactions = await MerchantWalletApi.getTransactions();
      
      // Load withdrawal summary
      WithdrawalSummaryDto? summary;
      try {
        summary = await _withdrawalDataSource.getSummary();
      } catch (e) {
        // Withdrawal summary is optional, don't fail if it errors
        print('Warning: Failed to load withdrawal summary: $e');
      }

      final balance = _toDouble(wallet['balance']);
      state = state.copyWith(
        balance: balance,
        availableBalance: summary?.availableBalance ?? balance,
        pendingWithdrawals: summary?.pendingWithdrawals ?? 0,
        transactions: transactions,
        withdrawalSummary: summary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: MerchantWalletApi.extractError(e),
      );
    }
  }

  Future<bool> transferToRider({
    required String recipientEmail,
    required double amount,
    String? note,
  }) async {
    if (!canManageWallet) {
      state = state.copyWith(
        error: 'Your staff role cannot send LeSpay payments.',
      );
      return false;
    }
    if (amount <= 0) {
      state = state.copyWith(error: 'Enter a valid amount.');
      return false;
    }
    if (amount > state.availableBalance) {
      state = state.copyWith(error: 'Insufficient LesPay balance.');
      return false;
    }

    state = state.copyWith(isTransferring: true, clearError: true);
    try {
      await MerchantWalletApi.transferToRider(
        recipientEmail: recipientEmail,
        amount: amount,
        note: note,
      );
      await loadWallet(silent: true);
      state = state.copyWith(isTransferring: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isTransferring: false,
        error: MerchantWalletApi.extractError(e),
      );
      return false;
    }
  }

  /// Request a withdrawal
  Future<WithdrawalRequestDto?> requestWithdrawal({
    required double amount,
    required String payoutMethod,
    required String payoutAccountNumber,
    required String payoutAccountName,
    String? payoutBankName,
  }) async {
    if (!canManageWallet) {
      state = state.copyWith(
        error: 'Your staff role cannot request withdrawals.',
      );
      return null;
    }

    // Validate amount
    final summary = state.withdrawalSummary;
    if (summary != null) {
      if (amount < summary.minWithdrawalAmount) {
        state = state.copyWith(
          error:
              'Minimum withdrawal amount is PHP ${summary.minWithdrawalAmount.toStringAsFixed(2)}.',
        );
        return null;
      }
      if (amount > summary.maxWithdrawalAmount) {
        state = state.copyWith(
          error:
              'Maximum withdrawal amount is PHP ${summary.maxWithdrawalAmount.toStringAsFixed(2)}.',
        );
        return null;
      }
    }

    if (amount <= 0) {
      state = state.copyWith(error: 'Enter a valid amount.');
      return null;
    }

    if (amount > state.availableBalance) {
      state = state.copyWith(
        error:
            'Insufficient available balance. You have PHP ${state.availableBalance.toStringAsFixed(2)} available.',
      );
      return null;
    }

    state = state.copyWith(isWithdrawing: true, clearError: true);
    try {
      final withdrawal = await _withdrawalDataSource.createWithdrawal(
        amount: amount,
        payoutMethod: payoutMethod,
        payoutAccountNumber: payoutAccountNumber,
        payoutAccountName: payoutAccountName,
        payoutBankName: payoutBankName,
      );

      // Reload wallet to update balances
      await loadWallet(silent: true);

      state = state.copyWith(isWithdrawing: false);
      return withdrawal;
    } catch (e) {
      state = state.copyWith(
        isWithdrawing: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  String transferPreview(double amount) {
    return MerchantTransferCommissionUtils.breakdownLabel(amount);
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

final merchantWalletProvider =
    StateNotifierProvider<MerchantWalletNotifier, MerchantWalletState>(
  (ref) => MerchantWalletNotifier(ref),
);
