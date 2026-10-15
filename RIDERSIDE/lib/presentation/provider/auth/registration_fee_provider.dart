import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/registration_fee_api.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../domain/entities/auth/registration_fee_status.dart';

class RegistrationFeeState {
  final RegistrationFeeStatus? status;
  final bool isLoading;
  final bool isProcessing;
  final bool checkoutOpened;
  final String? error;

  const RegistrationFeeState({
    this.status,
    this.isLoading = false,
    this.isProcessing = false,
    this.checkoutOpened = false,
    this.error,
  });

  RegistrationFeeState copyWith({
    RegistrationFeeStatus? status,
    bool clearStatus = false,
    bool? isLoading,
    bool? isProcessing,
    bool? checkoutOpened,
    String? error,
    bool clearError = false,
  }) {
    return RegistrationFeeState(
      status: clearStatus ? null : (status ?? this.status),
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      checkoutOpened: checkoutOpened ?? this.checkoutOpened,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RegistrationFeeNotifier extends StateNotifier<RegistrationFeeState> {
  RegistrationFeeNotifier({
    Future<RegistrationFeeStatus> Function()? fetchStatus,
    Future<RegistrationFeeCheckout> Function()? createCheckout,
    Future<RegistrationFeeStatus> Function({String? checkoutId})? verify,
  }) : _fetchStatus = fetchStatus ?? RegistrationFeeApi.fetchStatus,
       _createCheckout = createCheckout ?? RegistrationFeeApi.createCheckout,
       _verify = verify ?? RegistrationFeeApi.verifyPayment,
       super(const RegistrationFeeState());

  final Future<RegistrationFeeStatus> Function() _fetchStatus;
  final Future<RegistrationFeeCheckout> Function() _createCheckout;
  final Future<RegistrationFeeStatus> Function({String? checkoutId}) _verify;
  bool _fetching = false;

  Future<void> loadStatus({bool silent = false}) async {
    if (_fetching || state.isLoading || state.isProcessing) return;
    _fetching = true;
    if (!silent) {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearStatus: true,
      );
    }
    try {
      final status = await _fetchStatus();
      state = state.copyWith(
        status: status,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      AppLogger.error('Failed to load registration fee status', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Cannot check your registration status right now.',
      );
    } finally {
      _fetching = false;
    }
  }

  /// Creates a PayMongo checkout and returns the checkout URL to open,
  /// or `null` if it could not be created.
  Future<String?> payNow() async {
    if (_fetching || state.isProcessing) return null;
    final saved = state.status;
    if (saved?.isPendingPayment == true &&
        saved?.checkoutUrl?.isNotEmpty == true) {
      state = state.copyWith(checkoutOpened: true, clearError: true);
      return saved!.checkoutUrl;
    }
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final checkout = await _createCheckout();
      if (checkout.checkoutUrl == null || checkout.checkoutUrl!.isEmpty) {
        throw Exception('No payment link was returned.');
      }
      // Persist the successful checkout in state before the optional refresh.
      // A status outage must not discard its URL or create a second checkout.
      final previous = state.status;
      final pending = RegistrationFeeStatus(
        requiresFee: previous?.requiresFee ?? true,
        paymentWaived: false,
        canAccessApp: false,
        isActive: false,
        canAccessOperationalFeatures: false,
        paymentStatus: 'pending',
        applicationStatus: previous?.applicationStatus ?? 'pending',
        amount: checkout.amount > 0 ? checkout.amount : previous?.amount,
        billingPeriod: previous?.billingPeriod ?? 'one_time',
        currency: previous?.currency ?? 'PHP',
        checkoutUrl: checkout.checkoutUrl,
        paymongoCheckoutId: checkout.checkoutId,
        paymongoReference: checkout.paymongoReference,
      );
      state = state.copyWith(status: pending);
      var refreshed = pending;
      try {
        final status = await _fetchStatus();
        // A stale read immediately after creation can still report unpaid.
        if (!status.isUnpaid || status.checkoutUrl?.isNotEmpty == true) {
          refreshed = status;
        }
      } catch (e) {
        AppLogger.error('Checkout created; status refresh will be retried', e);
      }
      state = state.copyWith(
        status: refreshed,
        isProcessing: false,
        checkoutOpened: true,
      );
      return checkout.checkoutUrl;
    } catch (e) {
      AppLogger.error('Failed to create registration checkout', e);
      state = state.copyWith(
        isProcessing: false,
        error: ApiErrorMapper.message(e),
      );
      return null;
    }
  }

  Future<bool> verifyPayment() async {
    if (_fetching || state.isProcessing) return false;
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final status = await _verify(
        checkoutId: state.status?.paymongoCheckoutId,
      );
      state = state.copyWith(
        status: status,
        isProcessing: false,
        checkoutOpened: false,
      );
      return status.isActive;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Payment verification failed. Try again in a moment.',
      );
      return false;
    }
  }

  void setCheckoutOpened(bool opened) {
    state = state.copyWith(checkoutOpened: opened);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final registrationFeeProvider =
    StateNotifierProvider<RegistrationFeeNotifier, RegistrationFeeState>((ref) {
      return RegistrationFeeNotifier();
    });
