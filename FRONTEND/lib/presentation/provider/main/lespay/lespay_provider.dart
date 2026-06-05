import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/lespay_topup_fee.dart';
import '../../../../data/data_source/payment_gateway_remote_datasource.dart';
import '../../../../data/data_source/dto/payment/invoice_request_dto.dart';
import '../../../../data/data_source/dto/wallet/wallet_dto.dart';
import '../../../../data/data_source/wallet_remote_datasource.dart';
import '../../../../data/data_source/xendit_remote_datasource.dart';

enum TopUpInvoiceSource { walletApi, backendGateway, xenditDirect }

class TopUpCheckout {
  final String invoiceId;
  final String invoiceUrl;
  final double walletAmount;
  final double feeAmount;
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
  final bool walletLoaded;

  const LespayState({
    this.balance = 0,
    this.isLoading = false,
    this.isProcessingTopUp = false,
    this.error,
    this.pendingCheckout,
    this.transactions = const [],
    this.isLoadingTransactions = false,
    this.transactionsError,
    this.walletLoaded = false,
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
    bool? walletLoaded,
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
      walletLoaded: walletLoaded ?? this.walletLoaded,
    );
  }
}

class LespayNotifier extends StateNotifier<LespayState> {
  LespayNotifier() : super(const LespayState());

  Future<void> loadWallet() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final wallet = await getIt<WalletRemoteDataSource>().getMyWallet();
      state = state.copyWith(
        balance: wallet.balance,
        isLoading: false,
        walletLoaded: true,
        clearError: true,
      );
    } on DioException catch (e) {
      debugPrint('Wallet load failed: $e');
      state = state.copyWith(
        isLoading: false,
        walletLoaded: false,
        error: e.response?.statusCode == 401
            ? 'Please log in again.'
            : ApiErrorMapper.message(
                e,
                fallbackEn: 'Could not load LesPay wallet. Pull to retry.',
                fallbackTl: 'Hindi ma-load ang LesPay wallet. Subukan muli.',
              ),
      );
    } catch (e) {
      debugPrint('Wallet load failed: $e');
      state = state.copyWith(
        isLoading: false,
        walletLoaded: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load LesPay wallet. Pull to retry.',
          fallbackTl: 'Hindi ma-load ang LesPay wallet. Subukan muli.',
        ),
      );
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
        error: ApiErrorMapper.message(
          e,
          fallbackEn:
              'Top-up is unavailable right now. Please try again shortly.',
          fallbackTl:
              'Hindi available ang top-up ngayon. Subukan muli maya-maya.',
        ),
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
              'Payment not completed yet. Finish paying on the payment page, then tap again.',
        );
        return false;
      }

      try {
        await getIt<WalletRemoteDataSource>().confirmTopUp(
          amount: checkout.walletAmount,
          paymentMethod: 'xendit',
          xenditInvoiceId: checkout.invoiceId,
          externalReference: checkout.externalId,
        );
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code != 409) {
          final serverMsg = (e.response?.data is Map)
              ? (e.response!.data['message'] as String? ?? '')
              : '';
          state = state.copyWith(
            isProcessingTopUp: false,
            error: serverMsg.isNotEmpty
                ? serverMsg
                : 'Payment was received but could not be saved. '
                    'Please contact support with invoice ID: ${checkout.invoiceId}',
          );
          return false;
        }
      }

      await loadWallet();

      if (!state.walletLoaded) {
        state = state.copyWith(
          isProcessingTopUp: false,
          error:
              'Payment was received but your wallet balance could not be refreshed. '
              'Pull down to retry.',
        );
        return false;
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

  Future<void> refreshBalance() => loadWallet();

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
    } on DioException catch (e) {
      state = state.copyWith(
        isLoadingTransactions: false,
        transactionsError: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load transactions.',
          fallbackTl: 'Hindi ma-load ang transactions.',
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingTransactions: false,
        transactionsError: e.toString(),
      );
    }
  }

  /// Refresh wallet balance after an order paid with LesPay.
  Future<void> syncAfterWalletOrder(double amount) async {
    if (amount <= 0) return;
    await loadWallet();
    if (!state.walletLoaded) {
      state = state.copyWith(
        error: 'Could not verify LesPay balance after payment.',
      );
    } else if (state.balance < 0) {
      state = state.copyWith(error: 'Insufficient LesPay balance.');
    }
  }

  void clearPendingCheckout() {
    state = state.copyWith(clearPendingCheckout: true);
  }

  Future<TopUpCheckout> _createTopUpCheckout(double walletAmount) async {
    final pricing = LespayTopupFee.calculate(walletAmount);
    final description =
        'LesPay Top-up ₱${pricing.walletAmount.toStringAsFixed(2)} '
        '+ 3% fee (₱${pricing.feeAmount.toStringAsFixed(2)})';

    try {
      final invoiceData = await getIt<WalletRemoteDataSource>()
          .createTopUpInvoice(amount: pricing.walletAmount);
      final invoiceId = invoiceData['invoice_id']?.toString();
      final invoiceUrl = invoiceData['invoice_url']?.toString();
      if (invoiceId != null &&
          invoiceId.isNotEmpty &&
          invoiceUrl != null &&
          invoiceUrl.isNotEmpty) {
        return TopUpCheckout(
          invoiceId: invoiceId,
          invoiceUrl: invoiceUrl,
          walletAmount: pricing.walletAmount,
          feeAmount: pricing.feeAmount,
          totalCharge: pricing.totalCharge,
          source: TopUpInvoiceSource.walletApi,
          externalId: invoiceData['external_id']?.toString(),
        );
      }
    } catch (e) {
      debugPrint('Wallet API top-up invoice failed, trying gateway: $e');
    }

    try {
      final gateway = await getIt<PaymentGatewayRemoteDataSource>().createInvoice(
        InvoiceRequestDto(
          amount: pricing.walletAmount,
          description: description,
          paymentMethod: 'xendit',
          metadata: {
            'wallet_amount': pricing.walletAmount,
            'fee_amount': pricing.feeAmount,
            'purpose': 'lespay_topup',
          },
        ),
      );

      final invoiceUrl = gateway.data.invoiceUrl;
      if (invoiceUrl != null && invoiceUrl.isNotEmpty) {
        return TopUpCheckout(
          invoiceId: gateway.data.invoiceId,
          invoiceUrl: invoiceUrl,
          walletAmount: pricing.walletAmount,
          feeAmount: pricing.feeAmount,
          totalCharge: pricing.totalCharge,
          source: TopUpInvoiceSource.backendGateway,
        );
      }
    } catch (e) {
      debugPrint('Gateway top-up invoice failed, trying direct payment link: $e');
    }

    final invoice = await getIt<XenditRemoteDataSource>().createTopUpInvoice(
      amount: pricing.walletAmount,
      chargeAmount: pricing.totalCharge,
      description: description,
    );

    final directUrl = invoice.invoiceUrl;
    if (directUrl == null || directUrl.isEmpty) {
      throw Exception('Could not create a payment link for top-up.');
    }

    return TopUpCheckout(
      invoiceId: invoice.id,
      invoiceUrl: directUrl,
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
      fallbackEn: 'LesPay request failed. Please try again.',
      fallbackTl: 'Hindi natapos ang LesPay request. Subukan muli.',
    );
  }

  Future<bool> linkPaymentAccount(String provider) async {
    state = state.copyWith(isProcessingTopUp: true, clearError: true);
    try {
      await getIt<WalletRemoteDataSource>().linkAccount(
        provider: provider,
        accountLabel: switch (provider) {
          'maya' => 'PayMaya',
          'gcash' => 'GCash',
          _ => 'Bank Account',
        },
      );
      state = state.copyWith(isProcessingTopUp: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessingTopUp: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<bool> verifyLinkedAccount(String provider) async {
    try {
      await getIt<WalletRemoteDataSource>().verifyLinkedAccount(provider);
      return true;
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
      return false;
    }
  }
}

final lespayProvider = StateNotifierProvider<LespayNotifier, LespayState>((ref) {
  final notifier = LespayNotifier();
  notifier.loadWallet();
  notifier.loadTransactions();
  return notifier;
});
