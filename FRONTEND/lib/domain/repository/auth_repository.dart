import '../../data/data_source/dto/auth/otp_response_dto.dart';
import '../../data/data_source/dto/auth/register_request_dto.dart';
import '../../data/data_source/dto/auth/register_response_dto.dart';

/// Repository interface for authentication operations beyond login/logout.
/// Login/logout are already in [UserRepository] — this handles registration,
/// OTP, password reset, and profile management.
abstract class AuthRepository {
  /// Send OTP verification code.
  Future<OtpResponseDto> sendOtp(String phoneNumber, {String channel = 'sms'});

  /// Verify OTP code.
  Future<OtpResponseDto> verifyOtp(String phoneNumber, String otp);

  /// Cancel pending OTP.
  Future<OtpResponseDto> cancelOtp(String phoneNumber);

  /// Check if phone number is verified.
  Future<OtpResponseDto> checkOtpVerification(String phoneNumber);

  /// Register a new user.
  Future<RegisterResponseDto> register(RegisterRequestDto request);

  /// Send password reset OTP.
  Future<Map<String, dynamic>> sendPasswordResetOtp(String email);

  /// Verify password reset OTP.
  Future<Map<String, dynamic>> verifyPasswordResetOtp(String email, String otp);

  /// Reset password with OTP.
  Future<Map<String, dynamic>> resetPassword(String email, String otp, String password);

  /// Get current user profile.
  Future<Map<String, dynamic>> getProfile();

  /// Update user profile.
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data);

  /// Change password.
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String password,
  });

  /// Deactivate account.
  Future<Map<String, dynamic>> deactivateAccount({
    required String password,
    String? reason,
  });
}
