import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/di/injection.dart';
import '../../../../data/data_source/auth_remote_datasource.dart';
import 'register_state.dart';

mixin OtpNotifier on StateNotifier<RegisterState> {
  void updatePhoneNumber(String phoneNumber) {
    state = state.copyWith(data: state.data.copyWith(phoneNumber: phoneNumber));
  }

  Future<bool> sendOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authDataSource = getIt<AuthRemoteDataSource>();
      
      // Call Twilio Verify API through backend
      final response = await authDataSource.sendOtp(phoneNumber);
      
      if (response.success) {
        state = state.copyWith(
          data: state.data.copyWith(phoneNumber: phoneNumber),
          isLoading: false,
          otpSent: true,
        );
        return true;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      String errorMessage = 'Failed to send OTP';
      
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data['message'] != null) {
          errorMessage = e.response?.data['message'];
        } else if (e.message != null) {
          errorMessage = e.message!;
        }
      } else {
        errorMessage = e.toString();
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authDataSource = getIt<AuthRemoteDataSource>();
      final phoneNumber = state.data.phoneNumber;
      
      if (phoneNumber.isEmpty) {
        throw Exception('Phone number is required');
      }
      
      // Call Twilio Verify API through backend
      final response = await authDataSource.verifyOtp(phoneNumber, otp);
      
      if (response.success && (response.verified ?? false)) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        throw Exception('Invalid OTP code');
      }
    } catch (e) {
      String errorMessage = 'OTP verification failed';
      
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data['message'] != null) {
          errorMessage = e.response?.data['message'];
        } else if (e.message != null) {
          errorMessage = e.message!;
        }
      } else {
        errorMessage = e.toString();
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> resendOtp(String phoneNumber) async {
    // Resending is the same as sending for Twilio Verify
    return await sendOtp(phoneNumber);
  }

  Future<bool> cancelOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);

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
