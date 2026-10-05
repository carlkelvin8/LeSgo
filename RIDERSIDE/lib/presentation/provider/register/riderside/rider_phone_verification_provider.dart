import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../data/data_source/auth_remote_datasource.dart';

// Phone Verification State
class PhoneVerificationState {
  final String phoneNumber;
  final bool otpSent;
  final bool isLoading;
  final String? errorMessage;
  final bool isVerified;
  final String? devOtp; // Only in fallback/dev mode - shows OTP for testing

  const PhoneVerificationState({
    this.phoneNumber = '',
    this.otpSent = false,
    this.isLoading = false,
    this.errorMessage,
    this.isVerified = false,
    this.devOtp,
  });

  PhoneVerificationState copyWith({
    String? phoneNumber,
    bool? otpSent,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isVerified,
    String? devOtp,
  }) {
    return PhoneVerificationState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otpSent: otpSent ?? this.otpSent,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isVerified: isVerified ?? this.isVerified,
      devOtp: devOtp ?? this.devOtp,
    );
  }

  // Helper method to check if phone number is valid
  // Accept 10 digits (9xxxxxxxxx) or 11 digits starting with 0 (09xxxxxxxxx)
  bool get isPhoneNumberValid {
    if (phoneNumber.length == 10) return true;
    if (phoneNumber.length == 11 && phoneNumber.startsWith('0')) return true;
    return false;
  }
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
      // Strip leading 0 if present (e.g. 09171234567 -> 9171234567 -> +639171234567)
      String phone = state.phoneNumber;
      if (phone.startsWith('0')) {
        phone = phone.substring(1);
      }
      final formattedPhone = '+63$phone';
      
      // Call backend OTP API
      final response = await authDataSource.sendOtp(formattedPhone);
      
      if (response.success) {
        // In fallback/dev mode, backend returns the OTP in the response
        state = state.copyWith(
          otpSent: true,
          isLoading: false,
          devOtp: response.otp, // null in production, actual OTP in dev fallback
        );
        if (response.otp != null) {
          AppLogger.debug('DEV MODE - OTP Code: ${response.otp}');
        }
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
      
      AppLogger.error(
        'OTP Send DioError: ${e.type} - ${e.message}',
        e.response?.data,
      );
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      AppLogger.error('OTP Send Error', e);
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
      // Strip leading 0 if present
      String phone = state.phoneNumber;
      if (phone.startsWith('0')) {
        phone = phone.substring(1);
      }
      final formattedPhone = '+63$phone';
      
      // Call backend OTP API (resend is same as send)
      final response = await authDataSource.sendOtp(formattedPhone);
      
      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          clearError: true,
          devOtp: response.otp,
        );
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
      // Strip leading 0 if present
      String phone = state.phoneNumber;
      if (phone.startsWith('0')) {
        phone = phone.substring(1);
      }
      final formattedPhone = '+63$phone';
      
      // Call backend OTP verification API
      final response = await authDataSource.verifyOtp(formattedPhone, otp);
      
      if (response.success && (response.verified ?? false)) {
        state = state.copyWith(isLoading: false, isVerified: true);
        return true;
      } else {
        throw Exception(response.message);
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
