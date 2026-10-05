import 'package:injectable/injectable.dart';

import '../repository/user_repository.dart';

@lazySingleton
class LogoutUseCase {
  final UserRepository repository;

  LogoutUseCase(this.repository);

  Future<String> call() async {
    return await repository.logout();
  }
}
