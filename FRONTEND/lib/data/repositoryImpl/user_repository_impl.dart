import 'package:injectable/injectable.dart';

import '../../core/di/local_storage_service.dart';
import '../../domain/repository/user_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth/login/login_request.dart';
import '../data_source/user_remote_datasource.dart';
import '../data_source/dto/login/login_request_dto.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final LocalStorageService localStorageService;

  UserRepositoryImpl(this.remoteDataSource, this.localStorageService);

  @override
  Future<User> login(LoginRequest entity) async {
    // Map Domain Entity to Request DTO
    final requestDto = LoginRequestDto(
      email: entity.email,
      password: entity.password,
    );

    final dto = await remoteDataSource.login(requestDto);

    // Map DTO to Domain Entity
    // Using the User entity from domain/entities/user.dart
    // Note: Since we need to pass back success and messages to auth_provider, we throw an Exception on failure
    if (dto.success != true) {
      throw Exception(dto.message ?? 'Login failed');
    }

    final token = dto.token;
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token received');
    }

    await localStorageService.saveToken(token);

    final refreshToken = dto.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await localStorageService.saveRefreshToken(refreshToken);
    }

    return User(id: dto.id, email: dto.email, name: dto.name, token: token);
  }

  @override
  Future<String> logout() async {
    final token = localStorageService.token;
    if (token == null || token.isEmpty) {
      return 'Logged out successfully';
    }

    final dto = await remoteDataSource.logout(token);
    if (dto.success != true) {
      throw Exception(dto.message ?? 'Logout failed');
    }

    return dto.message ?? 'Logged out successfully';
  }
}
