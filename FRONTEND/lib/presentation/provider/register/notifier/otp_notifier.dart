import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../data/data_source/auth_remote_datasource.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/phone_utils.dart';
import 'register_state.dart';

mixin OtpNotifier on StateNotifier<RegisterState> {
  void updatePhoneNumber(String phoneNumber) {
    state = state.copyWith(
      data: state.data.copyWith(
        phoneNumber: PhoneUtils.normalizePh(phoneNumber),
      ),
    );
  }

  Future<bool> sendOtp(String phoneNumber) async {
    phoneNumber = PhoneUtils.normalizePh(phoneNumber);
    state = state.copyWith(
      isLoading: true,
      error: null,
      data: state.data.copyWith(phoneVerificationToken: ''),
    );

    try {
      final authDataSource = getIt<AuthRemoteDataSource>();

      // Call Twilio Verify API through backend
      final response = await authDataSource.sendOtp(phoneNumber);

      if (response.success) {
        // If fallback mode returned OTP directly, store it for auto-fill
        String? fallbackMessage;
        if (response.fallback == true && response.otp != null) {
          fallbackMessage = 'Dev mode: Your OTP is ${response.otp}';
        }

        state = state.copyWith(
          data: state.data.copyWith(phoneNumber: phoneNumber),
          isLoading: false,
          otpSent: true,
          error: fallbackMessage, // Show OTP as info message in fallback mode
        );
        return true;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      final errorMessage = ApiErrorMapper.message(
        e,
        fallbackEn: 'Could not send the verification code. Please try again.',
        fallbackTl: 'Hindi maipadala ang verification code. Subukan muli.',
      );

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      data: state.data.copyWith(phoneVerificationToken: ''),
    );

    try {
      final authDataSource = getIt<AuthRemoteDataSource>();
      final phoneNumber = state.data.phoneNumber;

      if (phoneNumber.isEmpty) {
        throw Exception('Phone number is required');
      }

      // Call Twilio Verify API through backend
      final response = await authDataSource.verifyOtp(phoneNumber, otp);
      if (state.data.phoneNumber != phoneNumber) {
        throw Exception('Phone number changed. Please verify it again.');
      }

      if (response.success && (response.verified ?? false)) {
        if (!(response.phoneVerificationToken?.isNotEmpty ?? false)) {
          throw Exception(
            'Phone verification could not be confirmed. Please request a new code.',
          );
        }
        state = state.copyWith(
          isLoading: false,
          data: state.data.copyWith(
            phoneVerificationToken: response.phoneVerificationToken,
          ),
        );
        return true;
      } else {
        throw Exception(
          response.message.isNotEmpty ? response.message : 'Invalid OTP code',
        );
      }
    } catch (e) {
      final errorMessage = ApiErrorMapper.message(
        e,
        fallbackEn: 'Could not verify the code. Please try again.',
        fallbackTl: 'Hindi ma-verify ang code. Subukan muli.',
      );

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> resendOtp(String phoneNumber) async {
    // Resending is the same as sending for Twilio Verify
    return await sendOtp(phoneNumber);
  }

  Future<bool> cancelOtp(String phoneNumber) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      data: state.data.copyWith(phoneVerificationToken: ''),
    );

    try {
      final authDataSource = getIt<AuthRemoteDataSource>();

      // Call cancel OTP API
      final response = await authDataSource.cancelOtp(phoneNumber);

      state = state.copyWith(isLoading: false);
      return response.success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel OTP: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> checkVerificationStatus(String phoneNumber) async {
    try {
      final authDataSource = getIt<AuthRemoteDataSource>();

      // Check if phone number is verified
      final response = await authDataSource.checkOtpVerification(phoneNumber);

      return response.verified ?? false;
    } catch (e) {
      return false;
    }
  }
}
