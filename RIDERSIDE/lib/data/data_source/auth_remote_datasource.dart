import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'helpers/register_driver_form_builder.dart';
import 'helpers/register_merchant_form_builder.dart';
import 'dto/auth/register_driver_request_dto.dart';
import 'dto/auth/register_driver_response_dto.dart';
import 'dto/auth/register_merchant_request_dto.dart';
import 'dto/auth/register_merchant_response_dto.dart';
import 'dto/auth/login_request_dto.dart';
import 'dto/auth/login_response_dto.dart';
import 'dto/auth/otp_response_dto.dart';

class AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSource(this._dioClient);

  // ============================================================================
  // OTP METHODS
  // ============================================================================

  /// Send OTP verification code to phone number
  Future<OtpResponseDto> sendOtp(
    String phoneNumber, {
    String channel = 'sms',
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/v1/auth/otp/send',
        data: {'phone_number': phoneNumber, 'channel': channel},
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
        data: {'phone_number': phoneNumber, 'otp': otp},
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
        data: {'phone_number': phoneNumber},
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
        data: {'phone_number': phoneNumber},
      );

      return OtpResponseDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // DRIVER REGISTRATION
  // ============================================================================

  /// Register new driver with optional document uploads (multipart).
  Future<RegisterDriverResponseDto> registerDriver(
    RegisterDriverRequestDto request, {
    Map<String, String>? documents,
  }) async {
    try {
      final dynamic payload;
      if (documents != null && documents.isNotEmpty) {
        payload = await buildRegisterDriverFormData(request, documents);
      } else {
        payload = request.toJson();
      }

      final response = await _dioClient.dio.post(
        '/v1/drivers/register',
        data: payload,
      );

      return RegisterDriverResponseDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // MERCHANT REGISTRATION
  // ============================================================================

  /// Register new merchant/partner with optional document uploads (multipart).
  Future<RegisterMerchantResponseDto> registerMerchant(
    RegisterMerchantRequestDto request, {
    Map<String, String>? documents,
  }) async {
    try {
      final dynamic payload;
      if (documents != null && documents.isNotEmpty) {
        payload = await buildRegisterMerchantFormData(request, documents);
      } else {
        payload = request.toJson();
      }

      final response = await _dioClient.dio.post(
        '/v1/auth/register',
        data: payload,
      );

      return RegisterMerchantResponseDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // LOGIN
  // ============================================================================

  /// Login user (driver or merchant)
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

  // ============================================================================
  // LOGOUT
  // ============================================================================

  /// Logout user
  Future<void> logout() async {
    try {
      await _dioClient.dio.post('/v1/auth/logout');
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // PROFILE
  // ============================================================================

  /// Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dioClient.dio.get('/v1/auth/me');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.put('/v1/auth/me', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // FORGOT PASSWORD
  // ============================================================================

  Future<Map<String, dynamic>> sendPasswordResetOtp(String email) async {
    final response = await _dioClient.dio.post(
      '/v1/auth/forgot-password/send-otp',
      data: {'email': email},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resendPasswordResetOtp(String email) async {
    final response = await _dioClient.dio.post(
      '/v1/auth/forgot-password/resend-otp',
      data: {'email': email},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyPasswordResetOtp(
    String email,
    String otp,
  ) async {
    final response = await _dioClient.dio.post(
      '/v1/auth/forgot-password/verify-otp',
      data: {'email': email, 'otp': otp},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String resetToken,
    String password,
  ) async {
    final response = await _dioClient.dio.post(
      '/v1/auth/forgot-password/reset',
      data: {
        'email': email,
        'reset_token': resetToken,
        'password': password,
        'password_confirmation': password,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Change password for signed-in user.
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String password,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.authChangePassword,
      data: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': password,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Deactivate the signed-in account.
  Future<Map<String, dynamic>> deactivateAccount({
    required String password,
    String? reason,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.authDeactivateAccount,
      data: {
        'password': password,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Permanently delete the signed-in driver/customer account.
  Future<Map<String, dynamic>> deleteAccountPermanently({
    required String password,
    required String confirmation,
    String? reason,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.authDeleteAccount,
      data: {
        'password': password,
        'confirmation': confirmation.trim().toUpperCase(),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
