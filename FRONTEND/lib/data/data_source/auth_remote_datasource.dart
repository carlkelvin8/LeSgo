import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import 'dto/auth/otp_response_dto.dart';
import 'dto/auth/login_request_dto.dart';
import 'dto/auth/login_response_dto.dart';
import 'dto/auth/register_request_dto.dart';
import 'dto/auth/register_response_dto.dart';

@injectable
class AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSource(this._dioClient);

  // ============================================================================
  // OTP METHODS
  // ============================================================================

  /// Send OTP verification code to phone number
  Future<OtpResponseDto> sendOtp(String phoneNumber, {String channel = 'sms'}) async {
    try {
      final response = await _dioClient.dio.post(
        '/v1/auth/otp/send',
        data: {
          'phone_number': phoneNumber,
          'channel': channel,
        },
      );

      return OtpResponseDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify OTP code for phone number
  Future<OtpResponseDto> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await _dioClient.dio.post(
        '/v1/auth/otp/verify',
        data: {
          'phone_number': phoneNumber,
          'otp': otp,
        },
      );

      return OtpResponseDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel pending OTP verification
  Future<OtpResponseDto> cancelOtp(String phoneNumber) async {
    try {
      final response = await _dioClient.dio.post(
        '/v1/auth/otp/cancel',
        data: {
          'phone_number': phoneNumber,
        },
      );

      return OtpResponseDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if phone number is verified
  Future<OtpResponseDto> checkOtpVerification(String phoneNumber) async {
    try {
      final response = await _dioClient.dio.post(
        '/v1/auth/otp/check',
        data: {
          'phone_number': phoneNumber,
        },
      );

      return OtpResponseDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // AUTH METHODS
  // ============================================================================

  /// Login user
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.loginEndpoint,
        data: request.toJson(),
      );

      return LoginResponseDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Register user
  Future<RegisterResponseDto> register(RegisterRequestDto request) async {
    try {
      final response = await _dioClient.dio.post(
        '/v1/auth/register',
        data: request.toJson(),
      );

      return RegisterResponseDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _dioClient.dio.post(ApiConstants.logoutEndpoint);
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.authMe);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.put(ApiConstants.authMe, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // FORGOT PASSWORD METHODS
  // ============================================================================

  /// Send password reset OTP to email
  Future<Map<String, dynamic>> sendPasswordResetOtp(String email) async {
    try {
      final response = await _dioClient.dio.post(
        '/v1/auth/forgot-password/send-otp',
        data: {'email': email},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Resend password reset OTP
  Future<Map<String, dynamic>> resendPasswordResetOtp(String email) async {
    try {
      final response = await _dioClient.dio.post(
        '/v1/auth/forgot-password/resend-otp',
        data: {'email': email},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Verify password reset OTP
  Future<Map<String, dynamic>> verifyPasswordResetOtp(String email, String otp) async {
    try {
      final response = await _dioClient.dio.post(
        '/v1/auth/forgot-password/verify-otp',
        data: {
          'email': email,
          'otp': otp,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password with OTP
  Future<Map<String, dynamic>> resetPassword(String email, String otp, String password) async {
    try {
      final response = await _dioClient.dio.post(
        '/v1/auth/forgot-password/reset',
        data: {
          'email': email,
          'otp': otp,
          'password': password,
          'password_confirmation': password,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}