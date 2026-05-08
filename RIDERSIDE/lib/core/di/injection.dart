import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../services/secure_storage_service.dart';
import '../../data/data_source/auth_remote_datasource.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core
  getIt.registerLazySingleton<DioClient>(() => DioClient());
  getIt.registerLazySingleton<SecureStorageService>(() => SecureStorageService());

  // Data Sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt<DioClient>()),
  );
}
