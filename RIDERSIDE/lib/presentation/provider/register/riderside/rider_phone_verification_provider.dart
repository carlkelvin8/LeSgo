import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      // TODO: Implement actual OTP sending API call
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(otpSent: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send OTP. Please try again.',
      );
    }
  }

  // Resend OTP
  Future<void> resendOTP() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: Implement actual resend OTP API call
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to resend OTP. Please try again.',
      );
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String otp) async {
    if (otp.length != 4) {
      state = state.copyWith(errorMessage: 'Please enter a valid 4-digit OTP');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: Implement actual OTP verification API call
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(isLoading: false, isVerified: true);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid OTP. Please try again.',
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
