import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/core/state/user_session_epoch.dart';
import '../../../../data/data_source/payment_remote_datasource.dart';
import '../../../../data/data_source/dto/payment/payment_dto.dart';
import '../../../../data/data_source/dto/payment/create_payment_request_dto.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/snackbar_utils.dart';

class PaymentState {
  final List<PaymentDto> payments;
  final PaymentDto? selectedPayment;
  final bool isLoading;
  final bool isCreating;
  final String? error;
  final String? filterStatus;
  final int? filterOrderId;

  PaymentState({
    this.payments = const [],
    this.selectedPayment,
    this.isLoading = false,
    this.isCreating = false,
    this.error,
    this.filterStatus,
    this.filterOrderId,
  });

  PaymentState copyWith({
    List<PaymentDto>? payments,
    PaymentDto? selectedPayment,
    bool? isLoading,
    bool? isCreating,
    String? error,
    String? filterStatus,
    int? filterOrderId,
  }) {
    return PaymentState(
      payments: payments ?? this.payments,
      selectedPayment: selectedPayment ?? this.selectedPayment,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      error: error,
      filterStatus: filterStatus ?? this.filterStatus,
      filterOrderId: filterOrderId ?? this.filterOrderId,
    );
  }

  List<PaymentDto> get completedPayments {
    return payments
        .where(
          (p) =>
              p.status.toLowerCase() == 'completed' ||
              p.status.toLowerCase() == 'success',
        )
        .toList();
  }

  List<PaymentDto> get pendingPayments {
    return payments.where((p) => p.status.toLowerCase() == 'pending').toList();
  }

  List<PaymentDto> get failedPayments {
    return payments
        .where(
          (p) =>
              p.status.toLowerCase() == 'failed' ||
              p.status.toLowerCase() == 'cancelled',
        )
        .toList();
  }

  double get totalAmount {
    return completedPayments.fold(0.0, (sum, payment) => sum + payment.amount);
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(PaymentState());

  /// Load all payments with optional filters
  Future<void> loadPayments({
    int? orderId,
    String? status,
    int perPage = 20,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      filterOrderId: orderId,
      filterStatus: status,
    );

    try {
      final paymentDataSource = getIt<PaymentRemoteDataSource>();
      final response = await paymentDataSource.getPayments(
        orderId: orderId,
        status: status,
        perPage: perPage,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(payments: response.data!, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load payments',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new payment
  Future<PaymentDto?> createPayment({
    required int orderId,
    required int customerId,
    required double amount,
    required String method,
    String? provider,
    String? providerReference,
    Map<String, dynamic>? meta,
    BuildContext? context,
  }) async {
    state = state.copyWith(isCreating: true, error: null);

    try {
      final paymentDataSource = getIt<PaymentRemoteDataSource>();
      final request = CreatePaymentRequestDto(
        orderId: orderId,
        customerId: customerId,
        amount: amount,
        method: method,
        provider: provider,
        providerReference: providerReference,
        meta: meta,
      );

      final response = await paymentDataSource.createPayment(request);

      if (response.success && response.data != null) {
        // Reload payments to get updated list
        await loadPayments();

        state = state.copyWith(
          isCreating: false,
          selectedPayment: response.data,
        );

        if (context != null && context.mounted) {
          SnackBarUtils.showSuccess(context, 'Payment created successfully');
        }
        return response.data;
      } else {
        state = state.copyWith(
          isCreating: false,
          error: response.error ?? 'Failed to create payment',
        );

        if (context != null && context.mounted) {
          SnackBarUtils.showError(
            context,
            response.error ?? 'Failed to create payment',
          );
        }
        return null;
      }
    } catch (e) {
      state = state.copyWith(isCreating: false, error: e.toString());

      if (context != null && context.mounted) {
        SnackBarUtils.showError(
          context,
          'Error creating payment: ${e.toString()}',
        );
      }
      return null;
    }
  }

  /// Get payment details by ID
  Future<void> getPaymentDetails(int paymentId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final paymentDataSource = getIt<PaymentRemoteDataSource>();
      final response = await paymentDataSource.getPayment(paymentId);

      if (response.success && response.data != null) {
        state = state.copyWith(
          selectedPayment: response.data,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to get payment details',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Filter payments by status
  void filterByStatus(String? status) {
    loadPayments(status: status, orderId: state.filterOrderId);
  }

  /// Filter payments by order ID
  void filterByOrderId(int? orderId) {
    loadPayments(orderId: orderId, status: state.filterStatus);
  }

  /// Clear all filters
  void clearFilters() {
    loadPayments();
  }

  /// Refresh payments
  Future<void> refreshPayments() async {
    await loadPayments(
      orderId: state.filterOrderId,
      status: state.filterStatus,
    );
  }

  /// Select a payment
  void selectPayment(PaymentDto payment) {
    state = state.copyWith(selectedPayment: payment);
  }

  /// Clear selected payment
  void clearSelectedPayment() {
    state = state.copyWith(selectedPayment: null);
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((
  ref,
) {
  ref.watch(userSessionEpochProvider);
  return PaymentNotifier();
});
