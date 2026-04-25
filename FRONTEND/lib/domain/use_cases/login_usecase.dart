import 'package:injectable/injectable.dart';

import '../repository/user_repository.dart';
import '../entities/user.dart';
import '../entities/auth/login/login_request.dart';

@lazySingleton
class LoginUseCase {
  final UserRepository repository;

  LoginUseCase(this.repository);

  Future<User> call(LoginRequest entity) async {
    return await repository.login(entity);
  }
}
