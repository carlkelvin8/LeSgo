import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../../../data/data_source/auth_remote_datasource.dart';
import 'auth_provider.dart';

enum ForgotPasswordStep { enterEmail, verifyOtp, resetPassword }

final forgotPasswordReturnViewProvider =
    StateProvider<AuthView>((ref) => AuthView.riderLogin);

class ForgotPasswordState {
  final ForgotPasswordStep step;
  final bool isLoading;
  final String? errorMessage;

  ForgotPasswordState({
    this.step = ForgotPasswordStep.enterEmail,
    this.isLoading = false,
    this.errorMessage,
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStep? step,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  final AuthRemoteDataSource _authDataSource;

  ForgotPasswordNotifier(this._authDataSource) : super(ForgotPasswordState());

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authDataSource.sendPasswordResetOtp(email);
      if (response['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          step: ForgotPasswordStep.verifyOtp,
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: response['message']?.toString() ?? 'Failed to send OTP',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> resendOtp(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authDataSource.resendPasswordResetOtp(email);
      if (response['success'] == true) {
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: response['message']?.toString() ?? 'Failed to resend OTP',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authDataSource.verifyPasswordResetOtp(email, otp);
      if (response['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          step: ForgotPasswordStep.resetPassword,
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: response['message']?.toString() ?? 'Invalid or expired OTP',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> resetPassword(String email, String otp, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authDataSource.resetPassword(email, otp, password);
      if (response['success'] == true) {
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: response['message']?.toString() ?? 'Failed to reset password',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void reset() {
    state = ForgotPasswordState();
  }
}

final forgotPasswordProvider =
    StateNotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>((ref) {
  return ForgotPasswordNotifier(getIt<AuthRemoteDataSource>());
});
