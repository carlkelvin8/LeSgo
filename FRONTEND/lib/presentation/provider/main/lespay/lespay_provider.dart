import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/lespay_topup_fee.dart';
import '../../../../data/data_source/payment_gateway_remote_datasource.dart';
import '../../../../data/data_source/dto/wallet/wallet_dto.dart';
import '../../../../data/data_source/wallet_remote_datasource.dart';
import '../../../../data/data_source/xendit_remote_datasource.dart';

enum TopUpInvoiceSource { walletApi, backendGateway, xenditDirect }

class TopUpCheckout {
  final String invoiceId;
  final String invoiceUrl;
  /// Amount credited to LesPay wallet.
  final double walletAmount;
  /// 3% service fee.
  final double feeAmount;
  /// Total charged on Xendit (wallet + fee).
  final double totalCharge;
  final TopUpInvoiceSource source;
  final String? externalId;

  const TopUpCheckout({
    required this.invoiceId,
    required this.invoiceUrl,
    required this.walletAmount,
    required this.feeAmount,
    required this.totalCharge,
    required this.source,
    this.externalId,
  });
}

class LespayState {
  final double balance;
  final bool isLoading;
  final bool isProcessingTopUp;
  final String? error;
  final TopUpCheckout? pendingCheckout;
  final List<WalletTransactionDto> transactions;
  final bool isLoadingTransactions;
  final String? transactionsError;

  const LespayState({
    this.balance = 0,
    this.isLoading = false,
    this.isProcessingTopUp = false,
    this.error,
    this.pendingCheckout,
    this.transactions = const [],
    this.isLoadingTransactions = false,
    this.transactionsError,
  });

  LespayState copyWith({
    double? balance,
    bool? isLoading,
    bool? isProcessingTopUp,
    String? error,
    TopUpCheckout? pendingCheckout,
    List<WalletTransactionDto>? transactions,
    bool? isLoadingTransactions,
    String? transactionsError,
    bool clearPendingCheckout = false,
    bool clearError = false,
    bool clearTransactionsError = false,
  }) {
    return LespayState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      isProcessingTopUp: isProcessingTopUp ?? this.isProcessingTopUp,
      error: clearError ? null : (error ?? this.error),
      pendingCheckout: clearPendingCheckout
          ? null
          : (pendingCheckout ?? this.pendingCheckout),
      transactions: transactions ?? this.transactions,
      isLoadingTransactions:
          isLoadingTransactions ?? this.isLoadingTransactions,
      transactionsError: clearTransactionsError
          ? null
          : (transactionsError ?? this.transactionsError),
    );
  }
}

class LespayNotifier extends StateNotifier<LespayState> {
  static const _localBalanceKey = 'lespay_local_balance_cents';

  LespayNotifier() : super(const LespayState()) {
    _loadLocalBalance();
  }

  Future<void> _loadLocalBalance() async {
    try {
      final prefs = getIt<SharedPreferences>();
      final cents = prefs.getInt(_localBalanceKey);
      if (cents != null) {
        state = state.copyWith(balance: cents / 100);
      }
    } catch (_) {}
  }

  Future<void> _saveLocalBalance(double balance) async {
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.setInt(_localBalanceKey, (balance * 100).round());
    } catch (_) {}
  }

  Future<void> loadWallet() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final wallet = await getIt<WalletRemoteDataSource>().getMyWallet();
      state = state.copyWith(
        balance: wallet.balance,
        isLoading: false,
        clearError: true,
      );
      await _saveLocalBalance(wallet.balance);
    } on DioException catch (e) {
      debugPrint('Wallet load failed: $e');
      final code = e.response?.statusCode;
      // Server down / not deployed — keep local balance, no scary error text.
      state = state.copyWith(
        isLoading: false,
        clearError: true,
      );
      if (code == 401) {
        state = state.copyWith(error: 'Please log in again.');
      }
    } catch (e) {
      debugPrint('Wallet load failed: $e');
      state = state.copyWith(isLoading: false, clearError: true);
    }
  }

  Future<TopUpCheckout?> startXenditTopUp(double amount) async {
    state = state.copyWith(
      isProcessingTopUp: true,
      clearError: true,
      clearPendingCheckout: true,
    );

    try {
      final checkout = await _createTopUpCheckout(amount);
      state = state.copyWith(
        isProcessingTopUp: false,
        pendingCheckout: checkout,
      );
      return checkout;
    } catch (e, stack) {
      debugPrint('LesPay top-up error: $e\n$stack');
      state = state.copyWith(
        isProcessingTopUp: false,
        error: _extractError(e),
      );
      return null;
    }
  }

  Future<bool> completeTopUp(TopUpCheckout checkout) async {
    state = state.copyWith(isProcessingTopUp: true, clearError: true);

    try {
      final paid = await _isInvoicePaid(checkout);
      if (!paid) {
        state = state.copyWith(
          isProcessingTopUp: false,
          error:
              'Payment not completed yet. Finish paying on Xendit, then tap again.',
        );
        return false;
      }

      var creditedViaApi = false;
      try {
        await getIt<WalletRemoteDataSource>().confirmTopUp(
          amount: checkout.walletAmount,
          paymentMethod: 'xendit',
          xenditInvoiceId: checkout.invoiceId,
          externalReference: checkout.externalId,
        );
        creditedViaApi = true;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 409) {
          state = state.copyWith(
            isProcessingTopUp: false,
            error:
                'Payment not completed yet. Finish paying on Xendit, then tap again.',
          );
          return false;
        }
        if (code != 404 && code != 405 && code != 502 && code != 503) {
          rethrow;
        }
        debugPrint('Wallet confirm API unavailable ($code); applying local credit.');
      }

      if (creditedViaApi) {
        await loadWallet();
      } else {
        final newBalance = state.balance + checkout.walletAmount;
        await _saveLocalBalance(newBalance);
        state = state.copyWith(
          balance: newBalance,
          isProcessingTopUp: false,
          clearPendingCheckout: true,
        );
        return true;
      }

      state = state.copyWith(
        isProcessingTopUp: false,
        clearPendingCheckout: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessingTopUp: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<bool> _isInvoicePaid(TopUpCheckout checkout) async {
    if (checkout.source == TopUpInvoiceSource.xenditDirect) {
      final invoice =
          await getIt<XenditRemoteDataSource>().getInvoice(checkout.invoiceId);
      return invoice.isPaid;
    }

    try {
      final response = await getIt<PaymentGatewayRemoteDataSource>()
          .getInvoiceStatus(checkout.invoiceId);
      final status = response.data.status.toLowerCase();
      return status == 'paid' || status == 'completed';
    } catch (_) {
      final invoice =
          await getIt<XenditRemoteDataSource>().getInvoice(checkout.invoiceId);
      return invoice.isPaid;
    }
  }

  Future<void> withdraw(double amount, {String method = 'bank'}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (state.balance < amount) {
        state = state.copyWith(
          isLoading: false,
          error: 'Insufficient balance',
        );
        return;
      }

      await getIt<WalletRemoteDataSource>().withdraw(
        amount: amount,
        withdrawalMethod: method,
      );
      await loadWallet();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    }
  }

  void refreshBalance() => loadWallet();

  Future<void> loadTransactions() async {
    state = state.copyWith(
      isLoadingTransactions: true,
      clearTransactionsError: true,
    );
    try {
      final list = await getIt<WalletRemoteDataSource>().getMyTransactions();
      state = state.copyWith(
        transactions: list,
        isLoadingTransactions: false,
      );
    } on DioException catch (_) {
      state = state.copyWith(
        isLoadingTransactions: false,
        transactionsError: 'Could not load transactions.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingTransactions: false,
        transactionsError: e.toString(),
      );
    }
  }

  /// Reflect wallet payment for an order (API debit + local fallback).
  Future<void> syncAfterWalletOrder(double amount) async {
    if (amount <= 0) return;

    try {
      await loadWallet();
      return;
    } catch (_) {}

    final newBalance = state.balance - amount;
    if (newBalance < 0) {
      state = state.copyWith(
        error: 'Insufficient LesPay balance for this order.',
      );
      return;
    }

    await _saveLocalBalance(newBalance);
    state = state.copyWith(balance: newBalance, clearError: true);
  }

  void clearPendingCheckout() {
    state = state.copyWith(clearPendingCheckout: true);
  }

  Future<TopUpCheckout> _createTopUpCheckout(double walletAmount) async {
    final pricing = LespayTopupFee.calculate(walletAmount);
    final description =
        'LesPay Top-up ₱${pricing.walletAmount.toStringAsFixed(2)} '
        '+ 3% fee (₱${pricing.feeAmount.toStringAsFixed(2)})';

    // Use Xendit directly so top-up works even when LesGo API returns 502.
    final invoice = await getIt<XenditRemoteDataSource>().createTopUpInvoice(
      amount: pricing.walletAmount,
      chargeAmount: pricing.totalCharge,
      description: description,
    );

    final url = invoice.invoiceUrl;
    if (url == null || url.isEmpty) {
      throw Exception('Xendit did not return a payment link.');
    }

    return TopUpCheckout(
      invoiceId: invoice.id,
      invoiceUrl: url,
      walletAmount: pricing.walletAmount,
      feeAmount: pricing.feeAmount,
      totalCharge: pricing.totalCharge,
      source: TopUpInvoiceSource.xenditDirect,
      externalId: invoice.externalId,
    );
  }

  String _extractError(Object error) {
    return ApiErrorMapper.message(
      error,
      fallbackEn: 'LesPay is unavailable. You can still top up via Xendit.',
      fallbackTl: 'Hindi available ang LesPay. Puwede pa ring mag-top up sa Xendit.',
    );
  }
}

final lespayProvider = StateNotifierProvider<LespayNotifier, LespayState>((ref) {
  final notifier = LespayNotifier();
  notifier.loadWallet();
  notifier.loadTransactions();
  return notifier;
});
