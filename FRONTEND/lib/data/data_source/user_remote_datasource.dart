import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/login/login_request_dto.dart';
import 'dto/logout/logout_response_dto.dart';
import 'dto/user/user_dto.dart';
import 'dto/user/user_response_dto.dart';
import 'dto/user/update_user_request_dto.dart';

@lazySingleton
class UserRemoteDataSource {
  final DioClient _dioClient;

  UserRemoteDataSource(this._dioClient);

  Future<UserDto> login(LoginRequestDto requestDto) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}',
        data: requestDto.toJson(),
      );

      return UserDto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data is Map<String, dynamic>) {
          return UserDto.fromJson(e.response?.data as Map<String, dynamic>);
        }
      }
      return UserDto.withError(
        e.message ?? 'An unexpected network error occurred',
      );
    } catch (e) {
      return UserDto.withError(e.toString());
    }
  }

  Future<LogoutResponseDto> logout(String token) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.logoutEndpoint}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return LogoutResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data is Map<String, dynamic>) {
          return LogoutResponseDto.fromJson(
            e.response?.data as Map<String, dynamic>,
          );
        }
      }
      return LogoutResponseDto.withError(
        e.message ?? 'An unexpected network error occurred',
      );
    } catch (e) {
      return LogoutResponseDto.withError(e.toString());
    }
  }

  /// Get current authenticated user
  Future<UserResponseDto> getMe() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get(ApiConstants.authMe);
      return UserResponseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Update current authenticated user
  Future<UserResponseDto> updateMe(UpdateUserRequestDto request) async {
    final dio = _dioClient.dio;
    try {
      print('🔵 UserRemoteDataSource: Updating profile...');
      print('🔵 Request data: ${request.toJson()}');
      
      final response = await dio.put(
        ApiConstants.authMe,
        data: request.toJson(),
      );
      
      print('🔵 UserRemoteDataSource: Update response - ${response.data}');
      return UserResponseDto.fromJson(response.data);
    } catch (e) {
      print('🔴 UserRemoteDataSource: Update failed - $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Get user by ID
  Future<UserResponseDto> getUser(int userId) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get(ApiConstants.userById(userId));
      return UserResponseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Update user by ID
  Future<UserResponseDto> updateUser(
    int userId,
    UpdateUserRequestDto request,
  ) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.patch(
        ApiConstants.userById(userId),
        data: request.toJson(),
      );
      return UserResponseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }
}
