import '../../domain/entities/user.dart';
import '../../domain/entities/auth/login/login_request.dart';

abstract class UserRepository {
  Future<User> login(LoginRequest entity);
  Future<String> logout();
}
