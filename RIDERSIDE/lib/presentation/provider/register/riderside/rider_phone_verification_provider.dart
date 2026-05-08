import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/di/injection.dart';
import '../../../../data/data_source/auth_remote_datasource.dart';

// Phone Verification State
class PhoneVerificationState {
  final String phoneNumber;
  final bool otpSent;
  final bool isLoading;
  final String? errorMessage;
  final bool isVerified;

  const PhoneVerificationState({
    this.phoneNumber = '',
    this.otpSent = false,
    this.isLoading = false,
    this.errorMessage,
    this.isVerified = false,
  });

  PhoneVerificationState copyWith({
    String? phoneNumber,
    bool? otpSent,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isVerified,
  }) {
    return PhoneVerificationState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otpSent: otpSent ?? this.otpSent,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isVerified: isVerified ?? this.isVerified,
    );
  }

  // Helper method to check if phone number is valid
  bool get isPhoneNumberValid => phoneNumber.length == 10;
}

class PhoneVerificationNotifier extends StateNotifier<PhoneVerificationState> {
  PhoneVerificationNotifier() : super(const PhoneVerificationState());

  // Update phone number
  void updatePhoneNumber(String phoneNumber) {
    state = state.copyWith(phoneNumber: phoneNumber, clearError: true);
  }

  // Send OTP
  Future<void> sendOTP() async {
    if (!state.isPhoneNumberValid) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid 10-digit phone number',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authDataSource = getIt<AuthRemoteDataSource>();
      
      // Format phone number to international format (+63)
      final formattedPhone = '+63${state.phoneNumber}';
      
      // Call backend OTP API
      final response = await authDataSource.sendOtp(formattedPhone);
      
      if (response.success) {
        state = state.copyWith(otpSent: true, isLoading: false);
      } else {
        throw Exception(response.message);
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to send OTP. Please try again.';
      
      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send OTP: ${e.toString()}',
      );
    }
  }

  // Resend OTP
  Future<void> resendOTP() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authDataSource = getIt<AuthRemoteDataSource>();
      
      // Format phone number to international format (+63)
      final formattedPhone = '+63${state.phoneNumber}';
      
      // Call backend OTP API (resend is same as send)
      final response = await authDataSource.sendOtp(formattedPhone);
      
      if (response.success) {
        state = state.copyWith(isLoading: false, clearError: true);
      } else {
        throw Exception(response.message);
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to resend OTP. Please try again.';
      
      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to resend OTP: ${e.toString()}',
      );
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String otp) async {
    if (otp.length != 6) {
      state = state.copyWith(errorMessage: 'Please enter a valid 6-digit OTP');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authDataSource = getIt<AuthRemoteDataSource>();
      
      // Format phone number to international format (+63)
      final formattedPhone = '+63${state.phoneNumber}';
      
      // Call backend OTP verification API
      final response = await authDataSource.verifyOtp(formattedPhone, otp);
      
      if (response.success && (response.verified ?? false)) {
        state = state.copyWith(isLoading: false, isVerified: true);
        return true;
      } else {
        throw Exception(response.message ?? 'Invalid OTP code');
      }
    } on DioException catch (e) {
      String errorMessage = 'Invalid OTP. Please try again.';
      
      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'OTP verification failed: ${e.toString()}',
      );
      return false;
    }
  }

  // Reset state
  void reset() {
    state = const PhoneVerificationState();
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final phoneVerificationProvider =
    StateNotifierProvider<PhoneVerificationNotifier, PhoneVerificationState>(
      (ref) => PhoneVerificationNotifier(),
    );
