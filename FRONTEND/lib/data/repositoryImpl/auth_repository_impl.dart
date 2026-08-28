import 'package:injectable/injectable.dart';

import '../../domain/repository/auth_repository.dart';
import '../data_source/auth_remote_datasource.dart';
import '../data_source/dto/auth/otp_response_dto.dart';
import '../data_source/dto/auth/register_request_dto.dart';
import '../data_source/dto/auth/register_response_dto.dart';

/// Implementation of [AuthRepository] that delegates to AuthRemoteDataSource.
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<OtpResponseDto> sendOtp(String phoneNumber, {String channel = 'sms'}) {
    return _remoteDataSource.sendOtp(phoneNumber, channel: channel);
  }

  @override
  Future<OtpResponseDto> verifyOtp(String phoneNumber, String otp) {
    return _remoteDataSource.verifyOtp(phoneNumber, otp);
  }

  @override
  Future<OtpResponseDto> cancelOtp(String phoneNumber) {
    return _remoteDataSource.cancelOtp(phoneNumber);
  }

  @override
  Future<OtpResponseDto> checkOtpVerification(String phoneNumber) {
    return _remoteDataSource.checkOtpVerification(phoneNumber);
  }

  @override
  Future<RegisterResponseDto> register(RegisterRequestDto request) {
    return _remoteDataSource.register(request);
  }

  @override
  Future<Map<String, dynamic>> sendPasswordResetOtp(String email) {
    return _remoteDataSource.sendPasswordResetOtp(email);
  }

  @override
  Future<Map<String, dynamic>> verifyPasswordResetOtp(
    String email,
    String otp,
  ) {
    return _remoteDataSource.verifyPasswordResetOtp(email, otp);
  }

  @override
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String resetToken,
    String password,
  ) {
    return _remoteDataSource.resetPassword(email, resetToken, password);
  }

  @override
  Future<Map<String, dynamic>> getProfile() {
    return _remoteDataSource.getProfile();
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) {
    return _remoteDataSource.updateProfile(data);
  }

  @override
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String password,
  }) {
    return _remoteDataSource.changePassword(
      currentPassword: currentPassword,
      password: password,
    );
  }

  @override
  Future<Map<String, dynamic>> deactivateAccount({
    String? password,
    String? googleIdToken,
    String? reason,
  }) {
    return _remoteDataSource.deactivateAccount(
      password: password,
      googleIdToken: googleIdToken,
      reason: reason,
    );
  }
}
