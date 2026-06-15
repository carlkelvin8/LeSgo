import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
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

  Map<String, dynamic> _normalizeAuthResponse(dynamic raw) {
    if (raw is! Map) return {};
    final map = Map<String, dynamic>.from(raw);
    if (map['data'] is Map) {
      final data = Map<String, dynamic>.from(map['data'] as Map);
      data['success'] ??= map['success'];
      data['message'] ??= map['message'];
      return data;
    }
    return map;
  }

  Future<UserDto> login(LoginRequestDto requestDto) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post(
        ApiConstants.loginEndpoint,
        data: requestDto.toJson(),
      );

      return UserDto.fromJson(_normalizeAuthResponse(response.data));
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data is Map<String, dynamic>) {
          return UserDto.fromJson(
            _normalizeAuthResponse(e.response?.data),
          );
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
        ApiConstants.logoutEndpoint,
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
      final raw = Map<String, dynamic>.from(response.data as Map);
      if (raw['data'] is Map && raw['user'] == null) {
        raw['user'] = raw['data'];
      }
      return UserResponseDto.fromJson(raw);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// POST /v1/auth/me/profile-picture — multipart profile photo upload.
  Future<UserResponseDto> uploadProfilePicture(XFile imageFile) async {
    final dio = _dioClient.dio;
    try {
      final bytes = await imageFile.readAsBytes();
      final filename =
          imageFile.name.isNotEmpty ? imageFile.name : 'profile.jpg';
      final formData = FormData.fromMap({
        'profile_picture': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await dio.post(
        '${ApiConstants.authMe}/profile-picture',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final raw = Map<String, dynamic>.from(response.data as Map);
      if (raw['data'] is Map && raw['user'] == null) {
        raw['user'] = raw['data'];
      }
      return UserResponseDto.fromJson(raw);
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Update current authenticated user
  Future<UserResponseDto> updateMe(UpdateUserRequestDto request) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.put(
        ApiConstants.authMe,
        data: request.toJson(),
      );

      return UserResponseDto.fromJson(response.data);
    } catch (e) {
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
