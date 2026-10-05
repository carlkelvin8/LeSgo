import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../services/connectivity_service.dart';
import '../services/secure_storage_service.dart';
import '../services/gemini_customer_service.dart';
import '../../data/data_source/auth_remote_datasource.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final dioClient = DioClient();
  dioClient.initialize();
  await connectivityService.checkConnection();

  getIt.registerLazySingleton<DioClient>(() => dioClient);
  getIt.registerLazySingleton<SecureStorageService>(() => SecureStorageService());

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt<DioClient>()),
  );

  if (!getIt.isRegistered<GeminiCustomerService>()) {
    getIt.registerLazySingleton<GeminiCustomerService>(
      () => GeminiCustomerService(),
    );
  }
}
