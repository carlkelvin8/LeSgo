import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../network/offline_request_queue.dart';
import '../services/connectivity_service.dart';
import '../services/secure_storage_service.dart';
import '../../data/data_source/auth_remote_datasource.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  await offlineRequestQueue.init();

  // Core — single shared Dio instance for the whole app
  final dioClient = DioClient();
  dioClient.initialize();
  connectivityService.attachDio(dioClient.dio);
  getIt.registerLazySingleton<DioClient>(() => dioClient);
  getIt.registerLazySingleton<SecureStorageService>(() => SecureStorageService());

  // Data Sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt<DioClient>()),
  );
}
