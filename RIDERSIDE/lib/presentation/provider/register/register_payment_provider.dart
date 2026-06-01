import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/api_service.dart';
import '../../../../data/data_source/auth_remote_datasource.dart';
import '../../../../data/data_source/dto/auth/login_request_dto.dart';
import '../../../../core/services/push_notification_service.dart';
import '../auth/auth_provider.dart';
import 'riderside/rider_phone_verification_provider.dart';
import 'riderside/rider_register_info_provider.dart';

enum RegisterPaymentRole { rider, merchant }

class RegisterPaymentState {
  final bool isProcessing;
  final bool isComplete;
  final String? errorMessage;

  const RegisterPaymentState({
    this.isProcessing = false,
    this.isComplete = false,
    this.errorMessage,
  });

  RegisterPaymentState copyWith({
    bool? isProcessing,
    bool? isComplete,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RegisterPaymentState(
      isProcessing: isProcessing ?? this.isProcessing,
      isComplete: isComplete ?? this.isComplete,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RegisterPaymentNotifier extends StateNotifier<RegisterPaymentState> {
  final Ref _ref;

  RegisterPaymentNotifier(this._ref) : super(const RegisterPaymentState());

  Future<bool> payRegistrationFee(RegisterPaymentRole role) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      if (role == RegisterPaymentRole.rider) {
        final info = _ref.read(registerInfoProvider).registrationInfo;
        final authDataSource = getIt<AuthRemoteDataSource>();
        final loginResponse = await authDataSource.login(
          LoginRequestDto(email: info.email, password: info.password),
        );
        if (loginResponse.token == null) {
          throw Exception('Login failed after registration. Please try logging in manually.');
        }
        await ApiService.saveToken(
          loginResponse.token!,
          expiresIn: loginResponse.expiresIn ?? 3600,
        );
      } else {
        final token = await ApiService.getToken();
        if (token == null) {
          throw Exception('Session expired. Please log in again.');
        }
      }

      await ApiService.dio.post('/v1/wallets/my/topup', data: {
        'amount': AppConfig.registrationFee,
        'payment_method': 'gcash',
        'purpose': 'registration_fee',
      });

      await PushNotificationService.registerWithBackend();

      state = state.copyWith(isProcessing: false, isComplete: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: ApiService.extractError(e),
      );
      return false;
    }
  }

  void resetFlow() {
    _ref.read(registerInfoProvider.notifier).reset();
    _ref.read(phoneVerificationProvider.notifier).reset();
    state = const RegisterPaymentState();
    _ref.read(authViewProvider.notifier).state = AuthView.welcome;
  }
}

final registerPaymentProvider =
    StateNotifierProvider<RegisterPaymentNotifier, RegisterPaymentState>((ref) {
  return RegisterPaymentNotifier(ref);
});
