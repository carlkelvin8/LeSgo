import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import 'dto/auth/register_driver_request_dto.dart';
import 'dto/auth/register_driver_response_dto.dart';
import 'dto/auth/register_merchant_request_dto.dart';
import 'dto/auth/register_merchant_response_dto.dart';
import 'dto/auth/login_request_dto.dart';
import 'dto/auth/login_response_dto.dart';

class AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSource(this._dioClient);

  // ============================================================================
  // DRIVER REGISTRATION
  // ============================================================================

  /// Register new driver
  Future<RegisterDriverResponseDto> registerDriver(
    RegisterDriverRequestDto request,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        '/v1/drivers/register',
        data: request.toJson(),
      );

      return RegisterDriverResponseDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // MERCHANT REGISTRATION
  // ============================================================================

  /// Register new merchant/partner
  Future<RegisterMerchantResponseDto> registerMerchant(
    RegisterMerchantRequestDto request,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        '/v1/auth/register',
        data: request.toJson(),
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
        '/v1/auth/login',
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
}
