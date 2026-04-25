import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/payment_gateway_remote_datasource.dart';
import '../../../../data/data_source/dto/payment/invoice_request_dto.dart';
import '../../../../data/data_source/dto/gateway/invoice_dto.dart';
import '../../../../data/data_source/dto/wallet/wallet_validation_dto.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../provider/auth/auth_provider.dart';

class PaymentGatewayState {
  final InvoiceDto? currentInvoice;
  final WalletValidationDto? walletValidation;
  final WalletThresholdDto? walletThreshold;
  final bool isLoading;
  final bool isCreatingInvoice;
  final bool isCheckingStatus;
  final String? error;
  final String? invoiceUrl;
  final bool canUseWallet;

  PaymentGatewayState({
    this.currentInvoice,
    this.walletValidation,
    this.walletThreshold,
    this.isLoading = false,
    this.isCreatingInvoice = false,
    this.isCheckingStatus = false,
    this.error,
    this.invoiceUrl,
    this.canUseWallet = false,
  });

  PaymentGatewayState copyWith({
    InvoiceDto? currentInvoice,
    WalletValidationDto? walletValidation,
    WalletThresholdDto? walletThreshold,
    bool? isLoading,
    bool? isCreatingInvoice,
    bool? isCheckingStatus,
    String? error,
    String? invoiceUrl,
    bool? canUseWallet,
  }) {
    return PaymentGatewayState(
      currentInvoice: currentInvoice ?? this.currentInvoice,
      walletValidation: walletValidation ?? this.walletValidation,
      walletThreshold: walletThreshold ?? this.walletThreshold,
      isLoading: isLoading ?? this.isLoading,
      isCreatingInvoice: isCreatingInvoice ?? this.isCreatingInvoice,
      isCheckingStatus: isCheckingStatus ?? this.isCheckingStatus,
      error: error,
      invoiceUrl: invoiceUrl ?? this.invoiceUrl,
      canUseWallet: canUseWallet ?? this.canUseWallet,
    );
  }

  bool get hasActiveInvoice => currentInvoice != null;
  
  bool get isInvoicePaid => 
      currentInvoice?.status.toLowerCase() == 'paid' ||
      currentInvoice?.status.toLowerCase() == 'completed';
  
  bool get isInvoicePending => 
      currentInvoice?.status.toLowerCase() == 'pending';
  
  bool get isInvoiceExpired => 
      currentInvoice?.status.toLowerCase() == 'expired';
}

class PaymentGatewayNotifier extends StateNotifier<PaymentGatewayState> {
  final Ref ref;

  PaymentGatewayNotifier(this.ref) : super(PaymentGatewayState());

  String? get _token {
    final authState = ref.read(authProvider);
    return authState.token;
  }

  /// Validate wallet balance
  Future<bool> validateWalletBalance({BuildContext? context}) async {
    if (_token == null) {
      if (context != null && context.mounted) {
        SnackBarUtils.showError(context, 'Please login first');
      }
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final gatewayDataSource = getIt<PaymentGatewayRemoteDataSource>();
      final validation = await gatewayDataSource.validateWalletBalance(_token!);

      state = state.copyWith(
        walletValidation: validation,
        canUseWallet: validation.isValid,
        isLoading: false,
      );

      return validation.isValid;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        canUseWallet: false,
      );

      if (context != null && context.mounted) {
        SnackBarUtils.showError(
          context,
          'Error validating wallet: ${e.toString()}',
        );
      }
      return false;
    }
  }

  /// Get wallet threshold
  Future<void> getWalletThreshold({BuildContext? context}) async {
    if (_token == null) {
      if (context != null && context.mounted) {
        SnackBarUtils.showError(context, 'Please login first');
      }
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final gatewayDataSource = getIt<PaymentGatewayRemoteDataSource>();
      final threshold = await gatewayDataSource.getWalletThreshold(_token!);

      state = state.copyWith(
        walletThreshold: threshold,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      if (context != null && context.mounted) {
        SnackBarUtils.showError(
          context,
          'Error getting threshold: ${e.toString()}',
        );
      }
    }
  }

  /// Create payment invoice (for top-up or order payment)
  Future<InvoiceDto?> createInvoice({
    required double amount,
    required String description,
    required String paymentMethod,
    String? successUrl,
    String? cancelUrl,
    Map<String, dynamic>? metadata,
    BuildContext? context,
  }) async {
    if (_token == null) {
      if (context != null && context.mounted) {
        SnackBarUtils.showError(context, 'Please login first');
      }
      return null;
    }

    state = state.copyWith(isCreatingInvoice: true, error: null);

    try {
      final gatewayDataSource = getIt<PaymentGatewayRemoteDataSource>();
      final request = InvoiceRequestDto(
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
        metadata: metadata,
      );

      final response = await gatewayDataSource.createInvoice(_token!, request);

      if (response.success && response.data?.invoice != null) {
        final invoice = response.data!.invoice!;
        state = state.copyWith(
          currentInvoice: invoice,
          invoiceUrl: invoice.invoiceUrl,
          isCreatingInvoice: false,
        );

        if (context != null && context.mounted) {
          SnackBarUtils.showSuccess(context, 'Invoice created successfully');
        }
        return invoice;
      } else {
        state = state.copyWith(
          isCreatingInvoice: false,
          error: response.error ?? 'Failed to create invoice',
        );

        if (context != null && context.mounted) {
          SnackBarUtils.showError(
            context,
            response.error ?? 'Failed to create invoice',
          );
        }
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isCreatingInvoice: false,
        error: e.toString(),
      );

      if (context != null && context.mounted) {
        SnackBarUtils.showError(
          context,
          'Error creating invoice: ${e.toString()}',
        );
      }
      return null;
    }
  }

  /// Check invoice status
  Future<InvoiceDto?> checkInvoiceStatus({
    required String invoiceId,
    BuildContext? context,
  }) async {
    if (_token == null) {
      if (context != null && context.mounted) {
        SnackBarUtils.showError(context, 'Please login first');
      }
      return null;
    }

    state = state.copyWith(isCheckingStatus: true, error: null);

    try {
      final gatewayDataSource = getIt<PaymentGatewayRemoteDataSource>();
      final response = await gatewayDataSource.getInvoiceStatus(_token!, invoiceId);

      if (response.success && response.data?.invoice != null) {
        final invoice = response.data!.invoice!;
        state = state.copyWith(
          currentInvoice: invoice,
          isCheckingStatus: false,
        );
        return invoice;
      } else {
        state = state.copyWith(
          isCheckingStatus: false,
          error: response.error ?? 'Failed to check invoice status',
        );

        if (context != null && context.mounted) {
          SnackBarUtils.showError(
            context,
            response.error ?? 'Failed to check invoice status',
          );
        }
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isCheckingStatus: false,
        error: e.toString(),
      );

      if (context != null && context.mounted) {
        SnackBarUtils.showError(
          context,
          'Error checking invoice: ${e.toString()}',
        );
      }
      return null;
    }
  }

  /// Create invoice for wallet top-up
  Future<InvoiceDto?> createTopUpInvoice({
    required double amount,
    required String paymentMethod,
    BuildContext? context,
  }) async {
    return await createInvoice(
      amount: amount,
      description: 'Wallet Top-up - ₱${amount.toStringAsFixed(2)}',
      paymentMethod: paymentMethod,
      metadata: {
        'type': 'wallet_topup',
        'amount': amount,
      },
      context: context,
    );
  }

  /// Create invoice for order payment
  Future<InvoiceDto?> createOrderPaymentInvoice({
    required int orderId,
    required double amount,
    required String paymentMethod,
    BuildContext? context,
  }) async {
    return await createInvoice(
      amount: amount,
      description: 'Order Payment - Order #$orderId',
      paymentMethod: paymentMethod,
      metadata: {
        'type': 'order_payment',
        'order_id': orderId,
        'amount': amount,
      },
      context: context,
    );
  }

  /// Clear current invoice
  void clearInvoice() {
    state = state.copyWith(
      currentInvoice: null,
      invoiceUrl: null,
    );
  }

  /// Reset state
  void reset() {
    state = PaymentGatewayState();
  }
}

final paymentGatewayProvider =
    StateNotifierProvider<PaymentGatewayNotifier, PaymentGatewayState>((ref) {
  return PaymentGatewayNotifier(ref);
});
