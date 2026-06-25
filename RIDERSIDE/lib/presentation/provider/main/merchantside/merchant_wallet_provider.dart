import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/merchant_wallet_api.dart';
import '../../../../core/utils/merchant_staff_permissions.dart';
import '../../../../core/utils/merchant_transfer_commission_utils.dart';
import '../../auth/rider_auth_provider.dart';

class MerchantWalletState {
  final double balance;
  final bool isLoading;
  final bool isTransferring;
  final String? error;
  final List<Map<String, dynamic>> transactions;

  const MerchantWalletState({
    this.balance = 0,
    this.isLoading = false,
    this.isTransferring = false,
    this.error,
    this.transactions = const [],
  });

  String get balanceFormatted => 'PHP ${balance.toStringAsFixed(2)}';

  MerchantWalletState copyWith({
    double? balance,
    bool? isLoading,
    bool? isTransferring,
    String? error,
    List<Map<String, dynamic>>? transactions,
    bool clearError = false,
  }) {
    return MerchantWalletState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      isTransferring: isTransferring ?? this.isTransferring,
      error: clearError ? null : (error ?? this.error),
      transactions: transactions ?? this.transactions,
    );
  }
}

class MerchantWalletNotifier extends StateNotifier<MerchantWalletState> {
  MerchantWalletNotifier(this.ref) : super(const MerchantWalletState()) {
    loadWallet();
  }

  final Ref ref;

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
      final balance = _toDouble(wallet['balance']);
      state = state.copyWith(
        balance: balance,
        transactions: transactions,
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
    if (amount > state.balance) {
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
